default['rackspace_logstash']['server']['version'] = '1.1.13'
default['rackspace_logstash']['server']['source_url'] = 'https://logstash.objects.dreamhost.com/release/logstash-1.1.13-flatjar.jar'
default['rackspace_logstash']['server']['checksum'] = '5ba0639ff4da064c2a4f6a04bd7006b1997a6573859d3691e210b6855e1e47f1'
default['rackspace_logstash']['server']['install_method'] = 'jar' # Either `source` or `jar`
default['rackspace_logstash']['server']['patterns_dir'] = 'server/etc/patterns'
default['rackspace_logstash']['server']['base_config'] = 'server.conf.erb'
default['rackspace_logstash']['server']['base_config_cookbook'] = 'logstash'
default['rackspace_logstash']['server']['xms'] = '1024M'
default['rackspace_logstash']['server']['xmx'] = '1024M'
default['rackspace_logstash']['server']['java_opts'] = ''
default['rackspace_logstash']['server']['gc_opts'] = '-XX:+UseParallelOldGC'
default['rackspace_logstash']['server']['ipv4_only'] = false
default['rackspace_logstash']['server']['debug'] = false
default['rackspace_logstash']['server']['home'] = '/opt/logstash/server'
default['rackspace_logstash']['server']['install_rabbitmq'] = true

default['rackspace_logstash']['server']['init_method'] = 'native' # native or runit
# roles/flags for various autoconfig/discovery components
default['rackspace_logstash']['server']['enable_embedded_es'] = true

default['rackspace_logstash']['server']['inputs'] = []
default['rackspace_logstash']['server']['filters'] = []
default['rackspace_logstash']['server']['outputs'] = []

default['rackspace_logstash']['server']['logrotate']['options'] = %w(missingok notifempty compress copytruncate)
