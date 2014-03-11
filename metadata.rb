name             'rackspace_logstash'
maintainer       'Rackspace'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs and configures logstash'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

%w{ ubuntu debian redhat centos }.each do |os|
  supports os
end

%w{ apache2 php build-essential git rbenv runit python java ant logrotate rabbitmq yumrepo }.each do |ckbk|
  depends ckbk
end

%w{ yumrepo apt }.each do |ckbk|
  recommends ckbk
end
