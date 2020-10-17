#
# Author:: Davin Taddeo (<davin@davintaddeo.com>)
# Cookbook:: chef_magic
# Library:: filesystem_helpers
#
# Copyright:: 2019-2020, Davin Taddeo

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

module ResourceDevelopment
  module FilesystemHelpers
    #
    # Define the methods that you would like to assist the work you do in recipes,
    # resources, or templates.
    #
    # def my_helper_method
    #   # help method implementation
    # end
    def system_root?
      sysroot = ''
      if windows?
        values = registry_get_values('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion')
        values.each do |reg_key|
          next unless reg_key[:name] == 'SystemRoot'
          sysroot = reg_key[:value]
        end
      else
        sysroot = '/'
      end
      sysroot
    end
  end
end

#
# The module you have defined may be extended within the recipe to grant the
# recipe the helper methods you define.
#
# Within your recipe you would write:
#
#     extend ResourceDevelopment::ResourceHelpersHelpers
#
#     my_helper_method
#
# You may also add this to a single resource within a recipe:
#
#     template '/etc/app.conf' do
#       extend ResourceDevelopment::ResourceHelpersHelpers
#       variables specific_key: my_helper_method
#     end
#
Chef::Resource.include ::ResourceDevelopment::FilesystemHelpers
Chef::DSL::Recipe.include ::ResourceDevelopment::FilesystemHelpers
Chef::Node.include ::ResourceDevelopment::FilesystemHelpers
