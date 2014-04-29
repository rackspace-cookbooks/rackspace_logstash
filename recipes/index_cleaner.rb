include_recipe 'python::pip'

base_dir          = File.join(node['rackspace_logstash']['basedir'], 'index_cleaner')
index_cleaner_bin = File.join(base_dir, 'logstash_index_cleaner.py')
days_to_keep      = node['rackspace_logstash']['index_cleaner']['days_to_keep']
log_file          = node['rackspace_logstash']['index_cleaner']['cron']['log_file']

python_pip 'pyes' do
  action :install
end

directory base_dir do
  action :create
  mode '0755'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
end

cookbook_file index_cleaner_bin do
  source 'logstash_index_cleaner.py'
  owner node['rackspace_logstash']['user']
  group node['rackspace_logstash']['group']
  mode '0774'
end

# FIXME: http://tickets.opscode.com/browse/CHEF-3547
file index_cleaner_bin do
  mode '0744'
  action :touch
  only_if { Chef::VERSION == '10.16.0' }
end

cron 'logstash_index_cleaner' do
  command "#{index_cleaner_bin} -d #{days_to_keep} &> #{log_file}"
  minute node['rackspace_logstash']['index_cleaner']['cron']['minute']
  hour node['rackspace_logstash']['index_cleaner']['cron']['hour']
end
