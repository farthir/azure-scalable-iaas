#
# Cookbook Name:: app-cookbook
# Recipe:: default
#
# Copyright (c) 2016 Rob Farthing, All Rights Reserved.

include_recipe 'java'

tomcat_install 'companynews' do
  version '8.5.3'
end

remote_file '/opt/tomcat_companynews/webapps/companyNews.war' do
  owner 'tomcat_companynews'
  mode '0644'
  source "#{node['app-cookbook']['war-source']}"
  action :create
end

directory '/Users/dcameron/persistence/files*' do
  owner 'tomcat_companynews'
  group 'tomcat_companynews'
  mode '0774'
  action :create
  recursive true
end

tomcat_service 'companynews' do
  action [:start, :enable]
  sensitive true
end