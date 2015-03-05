# dir
directory node[:nginx][:dir] do
  owner 'root'
  group 'root'
  mode '0755'
end
# nginx user/group
group "create nginx group" do
  group_name "nginx"
  action :create
end

user node[:passenger][:default_user] do
  action :create
  comment "deploy user"  
  gid "nginx"
  home "/home/deploy"
  supports :manage_home => true
  shell "/bin/bash"
  not_if do
    existing_usernames = []
    Etc.passwd {|user| existing_usernames << user['name']}
    existing_usernames.include?(node[:passenger][:default_user])
  end
end

directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:passenger][:default_user]
  action :create
end

%w{sites-available sites-enabled conf.d}.each do |dir|
  directory File.join(node[:nginx][:dir], dir) do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode 0755
    owner "root"
    group "root"
  end
end
template "#{node[:nginx][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
end

# create the init script from template
template "/etc/init.d/nginx" do
  source "nginx.passenger.init.erb"
  owner "root"
  group "root"
  mode 0655
end
# create the service config from template
template "/etc/sysconfig/nginx" do
  source "nginx.passenger.sysconfig.erb"
  owner "root"
  group "root"
  mode 0655
end
include_recipe "nginx::service"
template "#{node[:nginx][:dir]}/Gemfile" do
  source "passengerGem.erb"
end
# install it
bash "run bundle install" do
  cwd "#{node[:nginx][:dir]}"
  code "bundle install"
end
# install needed dep
package "gd-devel" do
  action :install
end
package "perl-ExtUtils-Embed" do
  action :install
end
package "GeoIP-devel" do
  action :install
end
package "gperftools-devel" do
  action :install
end
bash "run passenger install" do
  cwd "#{node[:nginx][:dir]}"
  code "bundle exec passenger-install-nginx-module --auto --auto-download  --prefix=/usr/share/nginx --extra-configure-flags=\"--prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/var/run/nginx.pid --lock-path=/var/lock/subsys/nginx --user=#{node[:passenger][:default_user]} --group=nginx --with-file-aio --with-ipv6 --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail_ssl_module --with-pcre --with-google_perftools_module --with-debug --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' --with-ld-opt=' -Wl,-E'\""
end

#passenger_root = `passenger-config --root`
#Chef::Log.info "$$$$$$$$$$$$$ -> passengger root from passenger-config -> #{passenger_root}"

# create the template
template "#{node[:nginx][:dir]}/stack.conf" do
  source "stack.conf.erb"
  owner "root"
  group "root"
  mode 00644
  variables (
    lazy {
     {:passenger_root => `bash -c "passenger-config --root"`.strip}
   }
    :passenger_max_pool_size => node[:passenger][:max_pool_size],
    :passenger_pool_idle_time => node[:passenger][:pool_idle_time],
    :passenger_default_user => node[:passenger][:default_user],
    :passenger_min_instances => node[:passenger][:min_instances],
    :passenger_buffer_size => node[:passenger][:buffer_size],
    :passenger_buffers => node[:passenger][:buffers],
    :passenger_busy_buffers_size => node[:passenger][:busy_buffers_size],
    :proxy_buffer_size => node[:proxy][:buffer_size],
    :proxy_buffers => node[:proxy][:buffers],
    :proxy_busy_buffers_size => node[:proxy][:busy_buffers_size]
  )
end

# more templates
template "/etc/nginx/http-custom.conf" do
  source "nginx.passenger.http-custom.conf.erb"
  owner "root"
  group "root"
  mode 0655
end
# cert files
directory "#{node[:nginx][:dir]}/ssl" do
  owner 'root'
  group 'root'
  mode '0755'
end
cookbook_file "#{node[:nginx][:dir]}/ssl/helpkit.crt" do
  source "helpkit.crt"
  mode "0744"
end
cookbook_file "#{node[:nginx][:dir]}/ssl/helpkit.key" do
  source "helpkit.key"
  mode "0744"
end
cookbook_file "#{node[:nginx][:dir]}/ssl/helpkit.pem" do
  source "helpkit.pem"
  mode "0744"
end
# server - helpkit
directory "#{node[:nginx][:dir]}/servers" do
  owner 'root'
  group 'root'
  mode '0755'
end
directory "#{node[:nginx][:dir]}/servers/helpkit" do
  owner 'root'
  group 'root'
  mode '0755'
end
directory "#{node[:nginx][:dir]}/servers/helpkit/ssl" do
  owner 'root'
  group 'root'
  mode '0755'
end
template "#{node[:nginx][:dir]}/servers/helpkit/helpkit.conf" do
  source "servers.helpkit.conf.erb"
  owner "root"
  group "root"
  mode 0655
end
template "#{node[:nginx][:dir]}/servers/helpkit/helpkit.ssl.conf" do
  source "servers.helpkit.ssl.conf.erb"
  owner "root"
  group "root"
  mode 0655
end
bash "passenger nginx empty files" do
    user "root"
    cwd "#{node[:nginx][:dir]}"
    code "touch #{node[:nginx][:dir]}/servers/helpkit/default.conf; touch #{node[:nginx][:dir]}/servers/helpkit/helpkit.rewrites; touch #{node[:nginx][:dir]}/servers/helpkit/helpkit.users; touch #{node[:nginx][:dir]}/servers/helpkit/ssl/custom.conf; touch #{node[:nginx][:dir]}/servers/helpkit/ssl/custom.ssl.conf; touch #{node[:nginx][:dir]}/servers/helpkit/custom.conf; touch #{node[:nginx][:dir]}/servers/helpkit/custom.ssl.conf"
end

bash "passenger make required dir" do
    user "root"
    code "mkdir /var/lib/nginx; mkdir /var/lib/nginx/tmp; chown -R #{node[:passenger][:default_user]}:nginx /var/lib/nginx;"
end
# create the template for the config
template "#{node[:nginx][:dir]}/nginx.conf" do
  source "nginx.passenger.conf.erb"
  owner "root"
  group "root"
  mode 00644
end
service "nginx" do
  action [ :enable, :start ]
end
# Include Recipes.
include_recipe 'nginx::logrotate'