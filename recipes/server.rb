#
# Author:: John E. Vincent
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Copyright 2012, John E. Vincent
# Copyright 2012, Bryan W. Berry
# License: Apache 2.0
# Cookbook Name:: logstash
# Recipe:: server
#
#

include_recipe 'java'
include_recipe 'rackspace_logstash::default'
include_recipe 'logrotate'

include_recipe 'rabbitmq' if node['rackspace_logstash']['server']['install_rabbitmq']

if node['rackspace_logstash']['install_zeromq']
  include_recipe 'yumrepo::zeromq' if platform_family?('rhel')
  node['rackspace_logstash']['zeromq_packages'].each { |p| package p }
end

if node['rackspace_logstash']['server']['init_method'] == 'runit'
  include_recipe 'runit'
  service_resource = 'runit_service[logstash_server]'
else
  service_resource = 'service[logstash_server]'
end

if node['rackspace_logstash']['server']['patterns_dir'][0] == '/'
  patterns_dir = node['rackspace_logstash']['server']['patterns_dir']
else
  patterns_dir = node['rackspace_logstash']['basedir'] + '/' + node['rackspace_logstash']['server']['patterns_dir']
end

if Chef::Config[:solo]
  es_server_ip = node['rackspace_logstash']['elasticsearch_ip']
  graphite_server_ip = node['rackspace_logstash']['graphite_ip']
else
  es_results = search(:node, node['rackspace_logstash']['elasticsearch_query'])
  graphite_results = search(:node, node['rackspace_logstash']['graphite_query'])

  if es_results.empty?
    es_server_ip = node['rackspace_logstash']['elasticsearch_ip']
  else
    es_server_ip = es_results[0]['ipaddress']
  end

  if graphite_results.empty?
    graphite_server_ip = node['rackspace_logstash']['graphite_ip']
  else
    graphite_server_ip = graphite_results[0]['ipaddress']
  end
end

# Create directory for logstash
directory "#{node['rackspace_logstash']['basedir']}/server" do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

%w(bin etc lib log tmp).each do |ldir|
  directory "#{node['rackspace_logstash']['basedir']}/server/#{ldir}" do
    action :create
    mode '0755'
    owner node['rackspace_logstash']['user']
    group node['rackspace_logstash']['group']
  end
end

# installation
if node['rackspace_logstash']['server']['install_method'] == 'jar'
  remote_file "#{node['rackspace_logstash']['basedir']}/server/lib/logstash-#{node['rackspace_logstash']['server']['version']}.jar" do
    owner 'root'
    group 'root'
    mode '0755'
    source node['rackspace_logstash']['server']['source_url']
    checksum node['rackspace_logstash']['server']['checksum']
    action :create_if_missing
  end

  link "#{node['rackspace_logstash']['basedir']}/server/lib/logstash.jar" do
    to "#{node['rackspace_logstash']['basedir']}/server/lib/logstash-#{node['rackspace_logstash']['server']['version']}.jar"
    notifies :restart, service_resource
  end
else
  include_recipe 'rackspace_logstash::source'

  logstash_version = node['rackspace_logstash']['source']['sha'] || "v#{node['rackspace_logstash']['server']['version']}"
  link "#{node['rackspace_logstash']['basedir']}/server/lib/logstash.jar" do
    to "#{node['rackspace_logstash']['basedir']}/source/build/logstash-#{logstash_version}-monolithic.jar"
    notifies :restart, service_resource
  end
end

directory "#{node['rackspace_logstash']['basedir']}/server/etc/conf.d" do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

directory patterns_dir do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

node['rackspace_logstash']['patterns'].each do |file, hash|
  template_name = patterns_dir + '/' + file
  template template_name do
    source 'patterns.erb'
    owner node['rackspace_logstash']['user']
    group node['rackspace_logstash']['group']
    variables(patterns: hash)
    mode '0644'
    notifies :restart, service_resource
  end
end

directory node['rackspace_logstash']['log_dir'] do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  recursive true
end

template "#{node['rackspace_logstash']['basedir']}/server/etc/logstash.conf" do
  source node['rackspace_logstash']['server']['base_config']
  cookbook node['rackspace_logstash']['server']['base_config_cookbook']
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  mode '0644'
  variables(graphite_server_ip: graphite_server_ip,
            es_server_ip: es_server_ip,
            enable_embedded_es: node['rackspace_logstash']['server']['enable_embedded_es'],
            es_cluster: node['rackspace_logstash']['elasticsearch_cluster'],
            patterns_dir: patterns_dir)
  notifies :restart, service_resource
  action :create
end

if node['rackspace_logstash']['server']['init_method'] == 'runit'
  runit_service 'logstash_server'
elsif node['rackspace_logstash']['server']['init_method'] == 'native'
  if platform_family? 'debian'
    if node['platform_version'] >= '12.04'
      template '/etc/init/logstash_server.conf' do
        mode '0644'
        source 'logstash_server.conf.erb'
      end

      service 'logstash_server' do
        provider Chef::Provider::Service::Upstart
        action [:enable, :start]
      end
    else
      Chef::Log.fatal("Please set node['rackspace_logstash']['server']['init_method'] to 'runit' for #{node['platform_version']}")
    end
  elsif platform_family? 'rhel', 'fedora'
    template '/etc/init.d/logstash_server' do
      source 'init.erb'
      owner 'root'
      group 'root'
      mode '0774'
      variables(config_file: 'logstash.conf',
                name: 'server',
                max_heap: node['rackspace_logstash']['server']['xmx'],
                min_heap: node['rackspace_logstash']['server']['xms']
                )
    end

    service 'logstash_server' do
      supports restart: true, reload: true, status: true
      action [:enable, :start]
    end
  end
else
  Chef::Log.fatal("Unsupported init method: #{node['rackspace_logstash']['server']['init_method']}")
end

logrotate_app 'logstash_server' do
  path "#{node['rackspace_logstash']['log_dir']}/*.log"
  frequency 'daily'
  rotate '30'
  options node['rackspace_logstash']['server']['logrotate']['options']
  create "664 #{node['rackspace_logstash']['user']} #{node['rackspace_logstash']['group']}"
end
