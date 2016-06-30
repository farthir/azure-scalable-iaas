#
# Cookbook Name:: web-cookbook
# Recipe:: default
#
# Copyright (c) 2016 farthir

package "bsdtar"

directory '/tmp/nginxchef' do
  action :create
end

directory "/var/www/#{node['web-cookbook']['static-dir-name']}" do
  action :create
  recursive true
end

remote_file '/tmp/nginxchef/static.zip' do
  source "#{node['web-cookbook']['zip-source']}"
  action :create
end

bash 'extract-static' do
  code <<-EOH
    bsdtar -xkf /tmp/nginxchef/static.zip -s'|[^/]*/||' -C "/var/www/#{node['web-cookbook']['static-dir-name']}"
    EOH
end

include_recipe 'nginx::default'

template '/etc/nginx/conf.d/tomcat-proxy.conf' do
  source 'tomcat-proxy.conf.erb'
  notifies :reload, 'service[nginx]', :immediately
end