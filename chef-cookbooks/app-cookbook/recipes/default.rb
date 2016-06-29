#
# Cookbook Name:: app-cookbook
# Recipe:: default
#
# Copyright (c) 2016 farthir

include_recipe 'java'

tomcat_install "#{node['app-cookbook']['war-name']}" do
  version '8.5.3'
end

remote_file "/opt/tomcat_#{node['app-cookbook']['war-name']}/webapps/#{node['app-cookbook']['war-name']}.war" do
  owner "tomcat_#{node['app-cookbook']['war-name']}"
  mode '0644'
  source "#{node['app-cookbook']['war-source']}"
  action :create
end

directory "#{node['app-cookbook']['prevayler-dir']}" do
  owner "tomcat_#{node['app-cookbook']['war-name']}"
  group "tomcat_#{node['app-cookbook']['war-name']}"
  mode '0774'
  action :create
  recursive true
end

tomcat_service "#{node['app-cookbook']['war-name']}" do
  action [:start, :enable]
  sensitive true
end