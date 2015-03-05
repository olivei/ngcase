execute "nginx restart" do
    user 'root'
    group 'root'
    command "sudo /etc/init.d/nginx restart"
    action :run
end
