#
# Chef Infra Documentation
# https://docs.chef.io/libraries/
#

#
# This module name was auto-generated from the cookbook name. This name is a
# single word that starts with a capital letter and then continues to use
# camel-casing throughout the remainder of the name.
#
module ChefMagic
  module AkvApiCheckout
    def akv_token(client_id, client_secret, tenant)
      token_uri = URI.parse("https://login.microsoftonline.com/#{tenant}/oauth2/token")
      resource = 'https://vault.azure.net'
      checkout = Net::HTTP.new(token_uri.host, token_uri.port)
      checkout.use_ssl = true
      req = Net::HTTP::Post.new(token_uri)
      req['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = "grant_type=client_credentials&client_id=#{client_id}&client_secret=#{client_secret}&resource=#{resource}"
      get_token = JSON.parse(checkout.request(req).body)
      puts get_token
      (get_token['access_token'] || {}).to_s
    # I removed the 200 check because it is in a rescue block so either JSON parse it or rescue and return empty object
    rescue
      {}
    end

    def akv_token_using_credentials_file(subscription_id, credentials_file)
      credentials_hash['azure_credentials'] = Tomlrb.load_file(credentials_file)
      client_id = credentials_hash['azure_credentials'][subscription_id]['client_id']
      client_secret = credentials_hash['azure_credentials'][subscription_id]['client_secret']
      tenant_id = credentials_hash['azure_credentials'][subscription_id]['tenant_id']
      akv_token(client_id, client_secret, tenant_id)
    end

    def akv_secret(secret_id, client_id, client_secret, tenant, vault, secret_name)
      api_token = akv_token(client_id, client_secret, tenant)
      secret_uri = URI.parse("https://#{vault}.vault.azure.net/secrets/#{secret_name}/#{secret_id}?api-version=7.0")
      header = { 'Authorization' => "Bearer #{api_token}", 'Content-Type' => 'application/json' }
      retrieve = Net::HTTP.new(secret_uri.host, secret_uri.port)
      retrieve.use_ssl = true if secret_uri.to_s.include?('https')
      get_secret_request = retrieve.get(secret_uri, header)
      get_secret = JSON.parse(get_secret_request.body)
      (get_secret['value'] || {}).to_s
    end
  end
end

Chef::DSL::Universal.include ::MetLife::AkvApiCheckout
