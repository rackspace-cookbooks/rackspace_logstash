#
# Author:: John E. Vincent
# Copyright 2012, John E. Vincent
# License: Apache 2.0
# Cookbook Name:: logstash
# Recipe:: pyshipper
#
#
include_recipe 'build-essential'
include_recipe 'rackspace_logstash::default'
include_recipe 'python::pip'
include_recipe 'git'

package 'python-dev'

git "#{node['rackspace_logstash']['basedir']}/shipper" do
  repository 'git://github.com/lusis/logstash-shipper.git'
  reference 'master'
  action :sync
end

%w(pyzmq-static simplejson argparse).each do |ppkg|
  python_pip ppkg do
    action :install
  end
end
