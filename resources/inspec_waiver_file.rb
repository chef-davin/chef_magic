require 'yaml'
require 'date'

provides :inspec_waiver_file
unified_mode true

description 'Use the **inspec_waiver_file** resource to add or remove entries from an inspec waiver file. This can be used in conjunction with the audit cookbook'

property :control, String,
  name_property: true,
  description: 'The name of the control being added or removed to the waiver file'

property :file, String,
  required: true,
  description: 'The path to the waiver file being modified'

property :expiration, String,
  description: 'The expiration date of the given waiver - provided in YYYY-MM-DD format',
  callbacks: {
    'Expiration date should match the following format: YYYY-MM-DD' => proc { |e|
      Date.valid_date?(*e.split('-').map(&:to_i))
    },
  }

property :run_test, [true, false],
  description: 'If present and true, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or false, the control will not be run.'

property :justification, String,
  description: 'Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver.'

property :backup, [false, Integer],
  description: 'The number of backups to be kept in /var/chef/backup (for UNIX- and Linux-based platforms) or C:/chef/backup (for the Microsoft Windows platform). Set to false to prevent backups from being kept.',
  default: false

action :add do
  filename = new_resource.file
  waiver_hash = load_waiver_file_to_hash(filename)
  control_hash = {}
  control_hash['expiration_date'] = new_resource.expiration.to_s unless new_resource.expiration.nil?
  control_hash['run'] = new_resource.run_test unless new_resource.run_test.nil?
  control_hash['justification'] = new_resource.justification.to_s

  unless waiver_hash[new_resource.control] == control_hash
    waiver_hash[new_resource.control] = control_hash
    waiver_hash = waiver_hash.sort.to_h

    file "Update Waiver File #{new_resource.file} to update waiver for control #{new_resource.control}" do
      path new_resource.file
      # content waiver_hash.to_yaml
      content YAML.dump(waiver_hash)
      backup new_resource.backup
      action :create
    end
  end
end

action :remove do
  filename = new_resource.file
  waiver_hash = load_waiver_file_to_hash(filename)
  if waiver_hash.key?(new_resource.control)
    waiver_hash.delete(new_resource.control)
    waiver_hash = waiver_hash.sort.to_h
    file "Update Waiver File #{new_resource.file} to remove waiver for control #{new_resource.control}" do
      path new_resource.file
      # content waiver_hash.to_yaml
      content YAML.dump(waiver_hash)
      backup new_resource.backup
      action :create
    end
  end
end

action_class do
  def load_waiver_file_to_hash(file_name)
    if file_name =~ %r{(/|C:\\).*(.yaml|.yml)}i
      if ::File.exist?(file_name)
        hash = ::YAML.load_file(file_name)
        if hash == false || hash.nil? || hash == ''
          {}
        else
          ::YAML.load_file(file_name)
        end
      else
        {}
      end
    else
      raise "Waivers file needs to be a YAML file which should have a .yaml or .yml extension -\"#{file_name}\" does not have an appropriate extension"
    end
  end
end
