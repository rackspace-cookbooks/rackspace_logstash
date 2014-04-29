#
# Cookbook Name:: logstash
# Recipe:: default
#
include_recipe 'runit' unless node['platform_version'] >= '12.04'

if node['rackspace_logstash']['create_account']

  group node['rackspace_logstash']['group'] do
    system true
  end

  user node['rackspace_logstash']['user'] do
    group node['rackspace_logstash']['group']
    home '/var/lib/logstash'
    system true
    action :create
    manage_home true
  end

end

directory node['rackspace_logstash']['basedir'] do
  action :create
  owner 'root'
  group 'root'
  mode '0755'
end

node['rackspace_logstash']['join_groups'].each do |grp|
  group grp do
    members node['rackspace_logstash']['user']
    action :modify
    append true
    only_if "grep -q '^#{grp}:' /etc/group"
  end
end
