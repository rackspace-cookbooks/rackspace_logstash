#
# Cookbook Name:: logstash
#
# Copyright 2014, Rackspace, UK, Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'logstash' do
  logstash_test_platforms.each do |platform, versions|
    describe "on #{platform}" do
      versions.each do |version|
        describe version do
          before :each do
          end
          let(:chef_run) do
            runner = ChefSpec::Runner.new(platform: platform.to_s, version: version.to_s)
            runner.converge('logstash')
          end
          it 'include the default recipe' do
            expect(chef_run).to include_recipe 'logstash'
          end
          it 'populate the opt/logstash directory' do
            expect(chef_run).to create_directory('/opt/logstash')
          end
          it 'creates the user logstash' do
            expect(chef_run).to create_user 'logstash'
          end
          it 'creates the group logstash' do
            expect(chef_run).to create_group 'logstash'
          end
        end
      end
    end
  end
end
