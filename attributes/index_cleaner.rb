default['rackspace_logstash']['index_cleaner']['days_to_keep'] = 31
default['rackspace_logstash']['index_cleaner']['cron'] = {
  'minute'   => '0',
  'hour'     => '*',
  'log_file' => '/dev/null'
}
