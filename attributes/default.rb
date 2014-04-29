default['rackspace_logstash']['basedir'] = '/opt/logstash'
default['rackspace_logstash']['user'] = 'logstash'
default['rackspace_logstash']['group'] = 'logstash'
default['rackspace_logstash']['join_groups'] = []
default['rackspace_logstash']['log_dir'] = '/var/log/logstash'
default['rackspace_logstash']['pid_dir'] = '/var/run/logstash'
default['rackspace_logstash']['create_account'] = true

# roles/flags for various search/discovery
default['rackspace_logstash']['graphite_role'] = 'graphite_server'
default['rackspace_logstash']['graphite_query'] = "roles:#{node['rackspace_logstash']['graphite_role']} AND chef_environment:#{node.chef_environment}"
default['rackspace_logstash']['elasticsearch_role'] = 'elasticsearch_server'
default['rackspace_logstash']['elasticsearch_query'] = "roles:#{node['rackspace_logstash']['elasticsearch_role']} AND chef_environment:#{node.chef_environment}"
default['rackspace_logstash']['elasticsearch_cluster'] = 'logstash'
default['rackspace_logstash']['elasticsearch_ip'] = ''
default['rackspace_logstash']['elasticsearch_port'] = ''
default['rackspace_logstash']['graphite_ip'] = ''

default['rackspace_logstash']['patterns'] = {}
default['rackspace_logstash']['install_zeromq'] = false

case node['platform_family']
when 'rhel'
  default['rackspace_logstash']['zeromq_packages'] = %w(zeromq zeromq-devel)
when 'debian'
  default['rackspace_logstash']['zeromq_packages'] = %w(zeromq libzmq-dev)
end
