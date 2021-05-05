require 'yaml'
require 'date'

provides :create_az_credentials_file
unified_mode true

property :file_directory, String, defaults: windows? ? 'C:\.azure' : '/root/.azure'
property :subscription_id, String, required: true
property :client_id, String, required: true
property :client_secret, String, required: true
property :tenant_id, String, required: true

action :create do
  credentials_hash = {
    "#{new_resource.subscription_id}": {
      client_id: new_resource.client_id,
      client_secret: new_resource.client_secret,
      tenant_id: new_resource.tenant_id,
    },
  }

  directory new_resource.file_directory do
    action :create
  end

  if windows?
    file "#{new_resource.file_directory}\\credentials" do
      content 'content'
      action :create
    end
  else
    file "#{new_resource.file_directory}/credentials" do
      content Dumper.toml_dump(credentials_hash)
      action :create
    end
  end
end
