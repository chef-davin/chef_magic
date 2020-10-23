chef_gem 'vault' do
  compile_time true
  action :install
end

%w( json toml yaml ).each do |i|
  override_file = "/tmp/override_file.#{i}"
  cookbook_file override_file do
    compile_time true
    source "override_file.#{i}"
  end
  override_hash = load_override_file(override_file)

  log "Using the #{i.upcase} override file and `get_override_file_value` method"
  log "#{get_override_file_value('linux_rd', 'override', 'favorsthebold', override_file)}"
  log "#{get_override_file_value('linux_rd', 'override', 'on_a_tuesday', override_file)}"
  log "#{get_override_file_value('linux_rd', 'override', 'things', override_file)}"

  log "Using the #{i.upcase} override file and `merge_override_hash` method to create node['override_#{i}']"
  case i.upcase
  when 'JSON'
    node.default['override_json'] = {}
    merge_override_hash(override_hash, node.default['override_json'])
    log "#{node['override_json']}"
  when 'TOML'
    node.default['override_toml'] = {}
    merge_override_hash(override_hash, node.default['override_toml'])
    log "#{node['override_toml']}"
  when 'YAML'
    node.default['override_yaml'] = {}
    merge_override_hash(override_hash, node.default['override_yaml'])
    log "#{node['override_yaml']}"
  end
end

log 'Fetching JSON data from a URL as input values.'
url_override_hash = load_override_url({
  'url' => 'https://raw.githubusercontent.com/chef-davin/chef_magic/main/test/cookbooks/test/files/override_file.json',
  'method' => 'GET',
  'header' => { 'Content-Type' => 'application/json', 'Accept' => 'application/json' },
  'body' => '' })
merge_override_hash(url_override_hash, node.default['override_from_url'])
log "#{node['override_from_url']}"
