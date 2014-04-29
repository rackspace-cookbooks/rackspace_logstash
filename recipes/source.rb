include_recipe 'build-essential'
include_recipe 'java'
include_recipe 'ant'
include_recipe 'git'
include_recipe 'rackspace_logstash::default'

package 'wget'

logstash_version = node['rackspace_logstash']['source']['sha'] || "v#{node['rackspace_logstash']['server']['version']}"

directory "#{node['rackspace_logstash']['basedir']}/source" do
  action :create
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  mode '0755'
end

git "#{node['rackspace_logstash']['basedir']}/source" do
  repository node['rackspace_logstash']['source']['repo']
  reference logstash_version
  action :sync
  user node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

execute 'build-logstash' do
  cwd "#{node['rackspace_logstash']['basedir']}/source"
  environment "{'JAVA_HOME' => node['rackspace_logstash']['source']['java_home']}"
  user 'root'
  # This variant is useful for troubleshooting stupid environment problems
  # command "make clean && make VERSION=#{logstash_version} --debug > /tmp/make.log 2>&1"
  command "make clean && make VERSION=#{logstash_version}"
  action :run
  creates "#{node['rackspace_logstash']['basedir']}/source/build/logstash-#{logstash_version}-monolithic.jar"
  not_if "test -f #{node['rackspace_logstash']['basedir']}/source/build/logstash-#{logstash_version}-monolithic.jar"
end
