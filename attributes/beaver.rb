
default['rackspace_logstash']['beaver']['pip_package'] = 'beaver==22'
default['rackspace_logstash']['beaver']['zmq']['pip_package'] = 'pyzmq==2.1.11'
default['rackspace_logstash']['beaver']['server_role'] = 'logstash_server'
default['rackspace_logstash']['beaver']['server_ipaddress'] = nil
default['rackspace_logstash']['beaver']['inputs'] = []
default['rackspace_logstash']['beaver']['outputs'] = []
default['rackspace_logstash']['beaver']['format'] = 'json'

default['rackspace_logstash']['beaver']['logrotate']['options'] = %w(missingok notifempty compress copytruncate)
default['rackspace_logstash']['beaver']['logrotate']['postrotate'] = 'invoke-rc.d logstash_beaver force-reload >/dev/null 2>&1 || true'
