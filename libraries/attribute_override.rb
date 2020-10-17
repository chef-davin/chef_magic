#
# Author:: Davin Taddeo (<davin@davintaddeo.com>)
# Cookbook:: chef_magic
# Library:: attribute_override
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

require 'yaml'
require 'tomlrb'

module ChefMagic
  module AttributeOverride
    # Finds a value in a hash by providing the hash name and the key
    #   that holds the desired value. Returns the value even if you don't
    #   know the whole hash chain.
    def find_hash_value(hash, key)
      if hash.respond_to?(:key?) && hash.key?(key)
        hash[key]
      elsif hash.respond_to?(:each)
        r = nil
        hash.find { |*a| r = find_hash_value(a.last, key) }
        r
      end
    end

    # Okay, Danger!, If you set the Destination hash to the node object,
    #   it will overwrite the node object at the hash destination hash level.
    #   If you don't want to overwite your node object completely,
    #   then you should probably use one of the other methods here
    def merge_override_hash(hash_src, hash_dest)
      ::Chef::Mixin::DeepMerge.deep_merge!(hash_src, hash_dest)
    end

    def load_override_file(file_path)
      if file_path =~ %r{(/|C:\\).*(.json|.yaml|.yml|.toml)}i
        case File.extname(file_path)
        when /(.yaml|.yml)/i
          all_attributes = YAML.load_file(file_path)
        when /.json/i
          all_attributes = JSON.parse(::File.read(file_path))
        when /.toml/i
          all_attributes = Tomlrb.load_file(file_path)
        end
        all_attributes
      else
        ::Chef.log.fatal('Overrides file needs to be a TOML, YAML, or JSON file')
      end
    end

    # This will extract a value from an override file and compare it
    #   to a value of the same key from the node object. If the override
    #   key/value exists, this will return the value from the overrides file
    #   rather than the corresponding node object.
    def get_override_file_value(first_node_key, first_override_key, returned_key, override_file = nil)
      # Parse the arguments passed to determine whether a file was given as the first argument
      if override_file =~ %r{(/|C:\\).*(.json|.yaml|.yml|.toml)}i
        file = override_file
      elsif windows? && override_file.nil?
        file = 'c:\chef\overrides.json'
      elsif !windows? && override_file.nil?
        file = '/etc/chef/overrides.json'
      end

      # get the leaf key of the hash path provided to the array
      last_key = returned_key

      # Yes, this uses the find_override_value() method, but it's run against on the node object
      default_attribute = find_hash_value(node[first_node_key], last_key)

      if File.exist?(file)
        all_override_attributes = load_override_file(file)
        override_attribute = find_hash_value(all_override_attributes[first_override_key], last_key)
        if override_attribute.nil?
          default_attribute
        else
          override_attribute
        end
      else
        default_attribute
      end
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::AttributeOverride
