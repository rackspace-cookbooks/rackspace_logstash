#
# Cookbook Name:: logstash
# Recipe:: beaver
#
#
include_recipe 'rackspace_logstash::default'
include_recipe 'python::default'
include_recipe 'logrotate'

if node['rackspace_logstash']['agent']['install_zeromq']
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
  python_pip node['rackspace_logstash']['beaver']['zmq']['pip_package'] do
    action :install
  end
end

package 'git'

basedir = node['rackspace_logstash']['basedir'] + '/beaver'

conf_file = "#{basedir}/etc/beaver.conf"
format = node['rackspace_logstash']['beaver']['format']
log_file = "#{node['rackspace_logstash']['log_dir']}/logstash_beaver.log"
pid_file = "#{node['rackspace_logstash']['pid_dir']}/logstash_beaver.pid"

logstash_server_ip = nil
if Chef::Config[:solo]
  logstash_server_ip = node['rackspace_logstash']['beaver']['server_ipaddress'] if node['rackspace_logstash']['beaver']['server_ipaddress']
elsif node['rackspace_logstash']['beaver']['server_ipaddress']
  logstash_server_ip = node['rackspace_logstash']['beaver']['server_ipaddress']
elsif node['rackspace_logstash']['beaver']['server_role']
  logstash_server_results = search(:node, "roles:#{node['rackspace_logstash']['beaver']['server_role']}")
  unless logstash_server_results.empty?
    logstash_server_ip = logstash_server_results[0]['ipaddress']
  end
end

# create some needed directories and files
directory basedir do
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  recursive true
end

[
  File.dirname(conf_file),
  File.dirname(log_file),
  File.dirname(pid_file)
].each do |dir|
  directory dir do
    owner node['rackspace_logstash']['user']
    group node['rackspace_logstash']['group']
    recursive true
    not_if { ::File.exist?(dir) }
  end
end

[log_file, pid_file].each do |f|
  file f do
    action :touch
    owner node['rackspace_logstash']['user']
    group node['rackspace_logstash']['group']
    mode '0640'
  end
end

python_pip node['rackspace_logstash']['beaver']['pip_package'] do
  action :install
end

# inputs
files = []
node['rackspace_logstash']['beaver']['inputs'].each do |ins|
  ins.each do |name, hash|
    case name
    when 'file' then
      if hash.key?('path')
        files << hash
      else
        log('input file has no path.') { level :warn }
      end
    else
      log("input type not supported: #{name}") { level :warn }
    end
  end
end

# outputs
outputs = []
conf = {}
node['rackspace_logstash']['beaver']['outputs'].each do |outs|
  outs.each do |name, hash|
    case name
    when 'rabbitmq', 'amqp' then
      outputs << 'rabbitmq'
     # host = hash['host'] || logstash_server_ip || 'localhost'
      conf['rabbitmq_host'] = hash['host'] if hash.key?('host')
      conf['rabbitmq_port'] = hash['port'] if hash.key?('port')
      conf['rabbitmq_vhost'] = hash['vhost'] if hash.key?('vhost')
      conf['rabbitmq_username'] = hash['user'] if hash.key?('user')
      conf['rabbitmq_password'] = hash['password'] if hash.key?('password')
      conf['rabbitmq_queue'] = hash['queue'] if hash.key?('queue')
      conf['rabbitmq_exchange_type'] = hash['rabbitmq_exchange_type'] if hash.key?('rabbitmq_exchange_type')
      conf['rabbitmq_exchange'] = hash['exchange'] if hash.key?('exchange')
      conf['rabbitmq_exchange_durable'] = hash['durable'] if hash.key?('durable')
      conf['rabbitmq_key'] = hash['key'] if hash.key?('key')
    when 'redis' then
      outputs << 'redis'
      host = hash['host'] || logstash_server_ip || 'localhost'
      port = hash['port'] || '6379'
      db = hash['db'] || '0'
      conf['redis_url'] = "redis://#{host}:#{port}/#{db}"
      conf['redis_namespace'] = hash['key'] if hash.key?('key')
    when 'stdout' then
      outputs << 'stdout'
    when 'zmq', 'zeromq' then
      outputs << 'zmq'
      host = hash['host'] || logstash_server_ip || 'localhost'
      port = hash['port'] || '2120'
      conf['zeromq_address'] = "tcp://#{host}:#{port}"
    else
      log("output type not supported: #{name}") { level :warn }
    end
  end
end

output = outputs[0]
if outputs.length > 1
  log("multiple outpus detected, will consider only the first: #{output}") { level :warn }
end

cmd = "beaver  -t #{output} -c #{conf_file} -F #{format}"

template conf_file do
  source 'beaver.conf.erb'
  mode 0640
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  variables(
            conf: conf,
            files: files
  )
  notifies :restart, 'service[logstash_beaver]'
end

# use upstart when supported to get nice things like automatic respawns
use_upstart = false
supports_setuid = false
case node['platform_family']
when 'rhel'
  if node['platform_version'].to_i >= 6
    use_upstart = true
  end
when 'fedora'
  if node['platform_version'].to_i >= 9
    use_upstart = true
  end
when 'debian'
  use_upstart = true
  if node['platform_version'].to_f >= 12.04
    supports_setuid = true
  end
end

if use_upstart
  template '/etc/init/logstash_beaver.conf' do
    mode '0644'
    source 'logstash_beaver.conf.erb'
    variables(
              cmd: cmd,
              group: node['rackspace_logstash']['group'],
              user: node['rackspace_logstash']['user'],
              log: log_file,
              supports_setuid: supports_setuid
              )
    notifies :restart, 'service[logstash_beaver]'
  end

  service 'logstash_beaver' do
    supports restart: true, reload: false
    action [:enable, :start]
    provider Chef::Provider::Service::Upstart
  end
else
  template '/etc/init.d/logstash_beaver' do
    mode '0755'
    source 'init-beaver.erb'
    variables(
              cmd: cmd,
              pid_file: pid_file,
              user: node['rackspace_logstash']['user'],
              log: log_file,
              platform: node['platform']
              )
    notifies :restart, 'service[logstash_beaver]'
  end

  service 'logstash_beaver' do
    supports restart: true, reload: false, status: true
    action [:enable, :start]
  end
end

logrotate_app 'logstash_beaver' do
  cookbook 'logrotate'
  path log_file
  frequency 'daily'
  postrotate node['rackspace_logstash']['beaver']['logrotate']['postrotate']
  options node['rackspace_logstash']['beaver']['logrotate']['options']
  rotate 30
  create "0640 #{node['rackspace_logstash']['user']} #{node['rackspace_logstash']['group']}"
end
