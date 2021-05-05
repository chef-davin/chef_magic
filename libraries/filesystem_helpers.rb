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

module ChefMagic
  module FilesystemHelpers
    # Return the windows %SystemRoot% registry entry.
    #
    # @return [String]
    #
    def system_root
      return '/' unless windows?

      values = registry_get_values('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion')
      key = values.find { |k| k[:name] == 'SystemRoot' }
      key[:value]
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::FilesystemHelpers
