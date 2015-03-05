Chef::Log.info "Logrotate for Nginx"
# Create Logrotate configuration file for Nginx.
template '/etc/logrotate.d/nginx' do
  source 'nginx.logrotate.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(
    'log_dir' => node[:nginx][:log_dir]
  )
  action 'create'
  only_if do
    File.directory?(node[:nginx][:log_dir])
  end
end
Chef::Log.info "Cron for Nginx Logrotate"
# Cron to trigger Logrotate for Nginx.
cron 'Logrotate Nginx' do
  hour '*'
  minute '0'
  user 'root'
  command %Q{ /usr/sbin/logrotate -f /etc/logrotate.d/nginx }
  action 'create'
end