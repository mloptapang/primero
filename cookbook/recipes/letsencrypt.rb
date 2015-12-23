letsencrypt_config_dir = "/etc/letsencrypt"
letsencrypt_dir = ::File.join(node[:primero][:home_dir], "letsencrypt")
letsencrypt_public_dir = ::File.join(node[:primero][:app_dir], "public")

git letsencrypt_dir do
  repository "https://github.com/letsencrypt/letsencrypt"
  action :sync
end

unless node[:primero][:letsencrypt][:email]
  Chef::Application.fatal!("You must specify the LetsEncrypt registration email in node[:primero][:letsencrypt][:email]!")
end

fullchain = ::File.join(letsencrypt_config_dir, 'live', node[:primero][:server_hostname], 'fullchain.pem')
privkey = ::File.join(letsencrypt_config_dir, 'live', node[:primero][:server_hostname], 'privkey.pem')

execute "Register Let's Encrypt Certificate" do
  command "./letsencrypt-auto certonly --webroot -w #{letsencrypt_public_dir} -d #{node[:primero][:server_hostname]} --agree-tos --email node[:primero][:letsencrypt][:email]"
  cwd letsencrypt_dir
  not_if do
    File.exist?(fullchain) &&
    File.exist?(privkey)
  end
end

#Update references to letsencrypt certs in app
certfiles = {
  '/etc/nginx/ssl/primero.crt' => fullchain,
  '/etc/nginx/ssl/primero.key' => privkey
}
if node[:primero][:letsencrypt][:couchdb]
  certfiles.merge({
    node[:primero][:couchdb][:cert_path] => fullchain,
    node[:primero][:couchdb][:key_path] => privkey
  })
end

certfiles.each do |certfile|
  already_symlinked = ::File.symlink?(certfile[0])

  file certfile[0] do
    action :delete
    not_if already_symlinked
  end

  link certfile[1] do
    to certfile[0]
    not_if already_symlinked
  end
end

#Restart nginx
service 'nginx' do
  action :restart
end

file "/etc/cron.monthly/letsencrypt_renew.sh" do
  mode '0755'
  owner "root"
  group "root"
  content <<EOH
#!/bin/bash

cd #{letsencrypt_dir}
./letsencrypt-auto certonly --webroot -w #{letsencrypt_public_dir} -d #{node[:primero][:server_hostname]} --agree-tos --email node[:primero][:letsencrypt][:email]
EOH
end


