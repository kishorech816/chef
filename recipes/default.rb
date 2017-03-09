#
# Cookbook Name:: jenkins
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#Add yum repos

yum_repository 'Active-Active' do
  
   only_if { ::File.exist?('/etc/yum.repos.d/Active-Active.repo') }
   action :delete
 end
 
 yun_repository 'Active-Active' do
   description ' Repository url for build repo which contain yum packages, if u have any custom repo '
   baseurl 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
   gpgcheck false
   sslVerify false
 action :add
 end
 
 #install pacakges
 %w(
 ant
 git
 java-1.7.0-openjdk
 npm
 ruby-dev1
 ruby-rdoc
 ruby-irb
 rubygems
 mysql-community-client
 unzip
 ).each do |p|
 yum_package p do
 action :install
end

yum_package 'jdk' do
 version node['jdk']['version']
 action [:install]
end

yum_pacakge 'jenkins' do
 version node['jenkins']['version'] + '-1.1'
 allow_downgrade true
 action [:install]
end

#install ruby gems
require 'rubygems'

%w(
sass
rhc
compass
compass-960-plugin
).each do |g|
 chef_gem g do
  options('--no-document')
  source node['rubygems']['gemrepo']
  clear_sources true
  compile_time true if Chef::Resource::ChefGem.instance_methods(false).include?(:compile_time)
  action :install
  end
 end
 
 #configure npm
 
 template 'npmrc' do
  path '/usr/etc/npmrc'
  source 'npmrc.erb'
  owner 'root'
  mode '0644'
 end
 
 cookbook_file "/home/#{node['jenkins']['user']}/.gitconfig"
  source 'mylogin.file'
  owner node['jenkins']['user']
  mode '0600'
  action :create
 end
 
 cookbook_file "/home/#{node['jenkins']['user']}/.bash_profile" do
  source 'jenkins-bash-profile.file'
  owner node['jenkins']['user']
  mode '0644'
  action :create
 end
 
 cookbook_file "/home/#{node['jenkins'['user']}/.profile" do
   source 'jenkins-bash-profile'
   owner node['jenkins']['user']
   mode '0644'
   action :create
  end
  
  cookbook_file "/home/#{node['jenkins']['user']}/.ssh/known_hosts" do
   source 'jenknins-known_hosts.file'
   owner node['jenkins']['user']
   mode '0644'
   action :create
  end
  
 execute "generate known hosts for #{node['jenkins']['user']}." do
  user node['jenkins']['user']
   command "ssh-keygen #{node['hostname']},#node['ipaddress']} >> /home/#{node['jenkins']['user']}/.ssh/known_hosts"
   not_if "grep \"#{node['hostname']},#{node['ipaddress']} $(cat /etc/ssh/ssh_host_rsa_key.pub | awk '${print $1,$2}')\" /home/#{node['jenkins']['user']}/.ssh/known_hosts"
 end
 
 #configure jenkins
 directory '/apps/jeknins/' do
  owner node['jenkins']['user']
  mode '0755'
  recursive true
  action :create
 end 
 
 
git '/apps/jenkins/' do
 repository 'xxxxxxxx.git'
 user node['jenkins']['user']
 enable_checkout false
 destination '/apps/jenkins'
 action :sync
end

#setup environment for node['jenkins']['user']

file '/apps/jenkins/.mylogin.cnf' do
 mode '0600'
 owner node['jenkins']['user']
end

git '/apps/jenkins/plugins' do
 repository 'ssh://xxxxxxxxxxxxx/JenkinsPlugins.git'
 user node['jenkins']['user']
 checkout_branch node['jenkins']['version']
 revision node['jenkins']['version']
 destinaation '/apps/jenkins/jobs'
 action :sync
end

execute 'Set upstream for jobs branch' do
 user node['jenkins']['user']
 cwd '/apps/jenkins/jobs'
 command 'git branch --set-upstream-to=origin/' + node['jenkins']['version'] + ' ' + node['jenkins']['version']
end

file '/apps/jenkins/.git/config' do
  mode '0644'
  owner 'root'
  group 'root'
 end
 
 file '/apps/jenkins/jobs/.git/config' do
  mode '0644'
  owner 'root'
  group 'root'
 end
 
 cookbook_file '/apps/jenkins/allowedVM.list' do
  source 'allowedVM.file'
  owner node['jenkins']['user']
  mode '0644'
  action :create_if_missing
 end
 
 template 'jenkins.model.JenkinsLocationConfiguration.xml' do
  path '/apps/jenkins/jenkins.model.JenkinsLocationConfiguration.xml'
  source 'JenkinsLocationConfiguration.erb'
  mode '0644'
  action :create
 end
 
 template 'config.xml' do
 path '/apps/jenkins/config.xml'
 source 'jenkins-main-config.erb'
 owner node['jenkins']['user']
 mode '0644'
 action :create
end

#insatll build tools

%w(
maven-3.0.5.zip
gradle-1.8.zip
gradle-2.0.zip
gradle-2.12.zip
java-1.6.0_25.zip
).each do |z|
 #break up the file names and from a vaild source url