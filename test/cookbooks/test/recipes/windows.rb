%w( json toml yml ).each do |i|
  override_file = "C:\\chef\\override_file.#{i}"
  cookbook_file override_file do
    compile_time true
    source "override_file.#{i}"
    cookbook 'chef_magic'
  end
  log "#{get_attribute('linux_rd', 'override', 'favorsthebold', override_file)}"
  log "#{get_attribute('linux_rd', 'override', 'on_a_tuesday', override_file)}"
  log "#{get_attribute('linux_rd', 'override', 'things', override_file)}"
end
