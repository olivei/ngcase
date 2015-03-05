# nginx settings
override[:nginx][:user]    = 'deploy'
override[:nginx][:log_dir] = '/var/log/nginx'
override[:nginx][:dir]     = '/etc/nginx'
override[:nginx][:binary]  = '/usr/sbin/nginx'
override[:nginx][:pid] 	  = '/var/run/nginx.pid'

# increase if you accept large uploads
override[:nginx][:client_max_body_size] = '4m'
override[:nginx][:gzip] = 'on'
override[:nginx][:gzip_static] = 'on'
override[:nginx][:gzip_vary] = 'on'
override[:nginx][:gzip_disable] = 'MSIE [1-6].(?!.*SV1)'
override[:nginx][:gzip_http_version] = '1.0'
override[:nginx][:gzip_comp_level] = '2'
override[:nginx][:gzip_proxied] = 'any'
override[:nginx][:gzip_types] = ['application/json',
								'text/plain',
								'text/css',
								'application/x-javascript',
								'text/xml',
								'application/xml',
								'application/rss+xml',
								'text/javascript']
override[:nginx][:gzip_buffers] = '16 8k'
# NGinx will compress 'text/html' by override
override[:nginx][:keepalive] = 'on'
override[:nginx][:keepalive_timeout] = 65
override[:nginx][:worker_processes] = 12
override[:nginx][:worker_connections] = 1024
override[:nginx][:server_names_hash_bucket_size] = 64
override[:nginx][:worker_rlimit_nofile] = 10240
# Fixes the IP for instances behind HAProxy
override[:nginx][:set_real_ip_from] = '10.0.0.0/8'
override[:nginx][:real_ip_header] = 'X-Forwarded-For' 
# passenger settings
host_name = node[:opsworks][:instance][:hostname]
layer = node[:opsworks][:instance][:layers].first
rails3_hosts=(node[:rails3][:hostnames] || [])
rails3_layers=(node[:rails3][:layers] || [])
if rails3_layers.include?(layer) || rails3_hosts.include?(host_name)
  override[:passenger][:version] = '4.0.59'
else
  override[:passenger][:version] = '3.0.21'
end
override[:passenger][:max_pool_size] = 12
override[:passenger][:pool_idle_time] = 3600
override[:passenger][:default_user] = 'deploy'
override[:passenger][:min_instances] = 6
override[:passenger][:buffer_size] = '128k'
override[:passenger][:buffers] = '4 256k' 
override[:passenger][:busy_buffers_size] = '256k'
# proxy to passenger settings
override[:proxy][:buffer_size] = '128k'
override[:proxy][:buffers] = '4 256k'
override[:proxy][:busy_buffers_size] = '256k'
