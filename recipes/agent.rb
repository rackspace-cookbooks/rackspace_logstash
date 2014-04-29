#
# Cookbook Name:: logstash
# Recipe:: agent
#
#
include_recipe 'java'
include_recipe 'rackspace_logstash::default'

if node['rackspace_logstash']['agent']['init_method'] == 'runit'
  include_recipe 'runit'
  service_resource = 'runit_service[logstash_agent]'
else
  service_resource = 'service[logstash_agent]'
end

if node['rackspace_logstash']['agent']['patterns_dir'][0] == '/'
  patterns_dir = node['rackspace_logstash']['agent']['patterns_dir']
else
  patterns_dir = node['rackspace_logstash']['basedir'] + '/' + node['rackspace_logstash']['agent']['patterns_dir']
end

if node['rackspace_logstash']['install_zeromq']
  case
  when platform_family?('rhel')
    include_recipe 'yumrepo::zeromq'
  when platform_family?('debian')
    apt_repository 'zeromq-ppa' do
      uri 'http://ppa.launchpad.net/chris-lea/zeromq/ubuntu'
      distribution node['lsb']['codename']
      components ['main']
      keyserver 'keyserver.ubuntu.com'
      key 'C7917B12'
      action :add
    end
    apt_repository 'libpgm-ppa' do
      uri 'http://ppa.launchpad.net/chris-lea/libpgm/ubuntu'
      distribution node['lsb']['codename']
      components ['main']
      keyserver 'keyserver.ubuntu.com'
      key 'C7917B12'
      action :add
      notifies :run, 'execute[apt-get update]', :immediately
    end
  end
  node['rackspace_logstash']['zeromq_packages'].each { |p| package p }
end

# check if running chef-solo.  If not, detect the logstash server/ip by role.  If I can't do that, fall back to using ['logstash']['agent']['server_ipaddress']
if Chef::Config[:solo]
  logstash_server_ip = node['rackspace_logstash']['agent']['server_ipaddress']
else
  logstash_server_results = search(:node, "roles:#{node['rackspace_logstash']['agent']['server_role']}")
  if logstash_server_results.empty?
    logstash_server_ip = node['rackspace_logstash']['agent']['server_ipaddress']
  else
    logstash_server_ip = logstash_server_results[0]['ipaddress']
  end
end

directory "#{node['rackspace_logstash']['basedir']}/agent" do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

%w(bin etc lib tmp log).each do |ldir|
  directory "#{node['rackspace_logstash']['basedir']}/agent/#{ldir}" do
    action :create
    mode '0755'
    owner node['rackspace_logstash']['user']
    group node['rackspace_logstash']['group']
  end

  link "/var/lib/logstash/#{ldir}" do
    to "#{node['rackspace_logstash']['basedir']}/agent/#{ldir}"
  end
end

directory "#{node['rackspace_logstash']['basedir']}/agent/etc/conf.d" do
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

if node['rackspace_logstash']['agent']['install_method'] == 'jar'
  remote_file "#{node['rackspace_logstash']['basedir']}/agent/lib/logstash-#{node['rackspace_logstash']['agent']['version']}.jar" do
    owner 'root'
    group 'root'
    mode '0755'
    source node['rackspace_logstash']['agent']['source_url']
    checksum node['rackspace_logstash']['agent']['checksum']
    action :create_if_missing
  end

  link "#{node['rackspace_logstash']['basedir']}/agent/lib/logstash.jar" do
    to "#{node['rackspace_logstash']['basedir']}/agent/lib/logstash-#{node['rackspace_logstash']['agent']['version']}.jar"
    notifies :restart, service_resource
  end
else
  include_recipe 'rackspace_logstash::source'

  logstash_version = node['rackspace_logstash']['source']['sha'] || "v#{node['rackspace_logstash']['server']['version']}"
  link "#{node['rackspace_logstash']['basedir']}/agent/lib/logstash.jar" do
    to "#{node['rackspace_logstash']['basedir']}/source/build/logstash-#{logstash_version}-monolithic.jar"
    notifies :restart, service_resource
  end
end

template "#{node['rackspace_logstash']['basedir']}/agent/etc/shipper.conf" do
  source node['rackspace_logstash']['agent']['base_config']
  cookbook node['rackspace_logstash']['agent']['base_config_cookbook']
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  mode '0644'
  variables(
            logstash_server_ip: logstash_server_ip,
            patterns_dir: patterns_dir)
  notifies :restart, service_resource
end

if node['rackspace_logstash']['agent']['init_method'] == 'runit'
  runit_service 'logstash_agent'
elsif node['rackspace_logstash']['agent']['init_method'] == 'native'
  if platform_family? 'debian'
    if node['platform_version'] >= '12.04'
      template '/etc/init/logstash_agent.conf' do
        mode '0644'
        source 'logstash_agent.conf.erb'
        notifies :restart, service_resource
      end

      service 'logstash_agent' do
        provider Chef::Provider::Service::Upstart
        action [:enable, :start]
      end
    else
      Chef::Log.fatal("Please set node['rackspace_logstash']['agent']['init_method'] to 'runit' for #{node['platform_version']}")
    end
  elsif platform_family? 'rhel', 'fedora'
    template '/etc/init.d/logstash_agent' do
      source 'init.erb'
      owner 'root'
      group 'root'
      mode '0774'
      variables(
        config_file: 'shipper.conf',
        name: 'agent',
        max_heap: node['rackspace_logstash']['agent']['xmx'],
        min_heap: node['rackspace_logstash']['agent']['xms']
      )
    end

    service 'logstash_agent' do
      supports restart: true, reload: true, status: true
      action :enable
    end
  end
else
  Chef::Log.fatal("Unsupported init method: #{node['rackspace_logstash']['server']['init_method']}")
end

logrotate_app 'logstash' do
  path "#{node['rackspace_logstash']['log_dir']}/*.log"
  frequency 'daily'
  rotate '30'
  options node['rackspace_logstash']['agent']['logrotate']['options']
  create "664 #{node['rackspace_logstash']['user']} #{node['rackspace_logstash']['group']}"
  notifies :restart, 'service[rsyslog]'
  if node['rackspace_logstash']['agent']['logrotate']['stopstartprepost']
    prerotate <<-EOF
      service logstash_agent stop
      logger stopped logstash_agent service for log rotation
    EOF
    postrotate <<-EOF
      service logstash_agent start
      logger started logstash_agent service after log rotation
    EOF
  end
end
