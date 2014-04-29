default['rackspace_logstash']['agent']['version'] = '1.1.13'
default['rackspace_logstash']['agent']['source_url'] = 'https://logstash.objects.dreamhost.com/release/logstash-1.1.13-flatjar.jar'
default['rackspace_logstash']['agent']['checksum'] = '5ba0639ff4da064c2a4f6a04bd7006b1997a6573859d3691e210b6855e1e47f1'
default['rackspace_logstash']['agent']['install_method'] = 'jar' # Either `source` or `jar`
default['rackspace_logstash']['agent']['patterns_dir'] = 'agent/etc/patterns'
default['rackspace_logstash']['agent']['base_config'] = 'agent.conf.erb'
default['rackspace_logstash']['agent']['base_config_cookbook'] = 'logstash'
default['rackspace_logstash']['agent']['xms'] = '384M'
default['rackspace_logstash']['agent']['xmx'] = '384M'
default['rackspace_logstash']['agent']['java_opts'] = ''
default['rackspace_logstash']['agent']['gc_opts'] = '-XX:+UseParallelOldGC'
default['rackspace_logstash']['agent']['ipv4_only'] = false
default['rackspace_logstash']['agent']['debug'] = false
# allow control over the upstart config
default['rackspace_logstash']['agent']['upstart_with_sudo'] = false
default['rackspace_logstash']['agent']['upstart_respawn_count'] = 5
default['rackspace_logstash']['agent']['upstart_respawn_timeout'] = 30

default['rackspace_logstash']['agent']['init_method'] = 'native' # native or runit

# logrotate options for logstash agent
default['rackspace_logstash']['agent']['logrotate']['options'] = %w(missingok notifempty)
# stop/start on logrotate?
default['rackspace_logstash']['agent']['logrotate']['stopstartprepost'] = false

# roles/flasgs for various autoconfig/discovery components
default['rackspace_logstash']['agent']['server_role'] = 'logstash_server'

# for use in case recipe used w/ chef-solo, default to self
default['rackspace_logstash']['agent']['server_ipaddress'] = ''

default['rackspace_logstash']['agent']['inputs'] = []
default['rackspace_logstash']['agent']['filters'] = []
default['rackspace_logstash']['agent']['outputs'] = []
