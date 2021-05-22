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

    # load_override_url - This will call a URL to load override data in JSON format rather than a path on the local filesystem.
    # Arguments should be provided in hash format:
    #   load_override_url({
    #     'url'     => 'http://some.web.site/uridata?optional=parameters',
    #     'method'  => 'GET',
    #     'header'  => { 'Content-Type' => 'application/json' },
    #     'body'    => { 'some_key' => 'some_value' }'
    #   })
    #   url:      Required - Full URL including protocol to invoke.
    #   method:   Optional - GET or POST method, will default to GET if no body is present and POST if a body is present.
    #   header:   Optional - header data in hash(key=>value) format for JSON or string format to be passed to URL.
    #   body:     Optional - body contents to be passed to url in STRING format.
    def load_override_url(hash)
      # Should not be needed to require net/http within Chef Infra client run, but being paranoid.
      require 'net/http'
      # Test if a valid Ruby hash was passed as the arguments
      if hash.class != Hash
        # Reply with a helpful error on why this is failing.
        err = <<~HASHERR
           load_override_url() method requires arguments to be passed in a Ruby hash:
           load_override_url({
               'url'     => 'http://some.web.site/uridata?optional=parameters',
               'method'  => 'GET',
               'header'  => { 'Content-Type' => 'application/json' },
               'body'    => { 'some_key' => 'some_value' }'
             })
        HASHERR
        raise err
      end
      # Make sure that there was a url included in the argument hash
      raise 'url is required for load_override_url' unless hash['url']
      # Parse the Net::HTTP URI from the provided url
      url = URI(hash['url'])
      # Take the method that was passed as an argument or guess what it is if no method was passed
      method = if hash['method']
                 hash['method'].downcase()
               elsif hash['body']
                 'post'
               else
                 'get'
               end
      # Validate that the method passed is supported
      unless %w(get post).include?(method)
        raise "Unsupported method '#{method}' passed for load_override_url, supported methods are GET and POST"
      end
      # Parse header data from
      headers = hash['header']
      body = hash['body']
      case method
      when 'post'
        begin
          # Parse the body and prepare to send it
          body_object = if headers =~ %r{application/json} || JSON.parse(body)
                          puts 'Converting body argument to JSON type'
                          JSON.parse(body)
                        else
                          puts 'Treating body as STRING'
                          body.to_s
                        end
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true if http.port.to_s =~ /443/
          req = Net::HTTP::Post.new(url)
          # Add the header objects to the req object
          req = req.merge(headers)
          req.body = body_object
          JSON.parse(http.request(req).body)
        rescue => err
          # TODO: add logic for a retry of status POST
          puts
          puts 'There was an error sending POST to load_override_url'
          puts err
        end
      when 'get'
        begin
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true if http.port.to_s =~ /443/
          req = http.get(url, headers)
          JSON.parse(req.body)
        rescue => err
          puts
          puts 'There was an error sending GET to load_override_url'
          puts err
        end
      else
        puts "method #{method} was specified but no action exists for this method.  Did you mean get/put/post?"
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

    # This will extract a value from an override hash and compare it
    #   to a value of the same key from the node object. If the override
    #   key/value exists, this will return the value from the overrides hash
    #   rather than the corresponding node object.
    # This is designed to be used in conjunction with the load_override_file() method.
    def get_override_hash_value(node_hash, override_hash, desired_key)
      # Query the hash of the node object to find the value of the desired attribute
      default_attribute = find_hash_value(node_hash, desired_key)

      # Query the hash of the override hash object to find the value of the desired attribute
      override_attribute = find_hash_value(override_hash, desired_key)

      # If the override attribute doesn't exist, return the attribute from the node object
      #   if it does exist, return the object from the override hash.
      if override_attribute.nil?
        default_attribute
      else
        override_attribute
      end
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::AttributeOverride
