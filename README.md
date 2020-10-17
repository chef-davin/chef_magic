# chef_magic

This cookbook is designed to provide tools to help users scale their use of Chef without creating massive amounts of overcomplexity.  There are tools used to allow for secondary sources of attribute data that are outside of the builtin standards for Policyfiles and/or Effortless packages.

Though not available just yet, hopefully in the future there will be utilities for interracting easily with other enterprise tools like Hashicorp Vault or CyberArk or other APIs that might be used in large scale environments to disseminate configuration needs.

## Resources

There are no resources yet in this cookbook.  But there could be soon!

## Helper Methods

These are a series of methods/libraries created to help with various needs you might find when
  working with a large group of machines managed/created with many different paradigms or needing the ability to modify how Chef functions without having to build a new Effortless Package or Chef Policy.

## Filesystem Helpers

### `system_root?`

  The `system_root?` method was designed to grab the equivalent of the `%systemroot%` environment variable on a Windows system.  It queries the registry of the Windows system to provide this.

  If used on a non-Windows system, it will return `/`.

## Attribute Override helpers

### `load_override_file(file)`

Reads in a TOML, YAML, or JSON file and returns a hash of the values provided in the file that can then be referenced in your recipe.

**Load a hash variable, and use an if block to load the override value over the node value**:

```ruby
system_overrides['base_recipe'] = load_override_file('C:\chef\overrides.toml')

enablelua_value = if system_overrides['base_recipe']['registry_keys'].key?('enable_lua')
                    system_overrides['base_recipe']['registry_keys']['enable_lua']
                  else
                    node['base_recipe']['registry_keys']['enable_lua']
                  end

registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
  values [{ name: 'EnableLUA', type: :dword, data: enablelua_value }]
  action :create
end
```

### `get_override_file_value(first_node_hash_key, first_override_hash_key, desired_hash_key, [override_file])`

This will extract a value from an override file and compare it to a value of the same key from the node object. If the override key/value exists, this will return the value from the overrides file rather than the corresponding node object.

#### This method takes four values, but the fourth is optional as there are defaults

**first_node_hash_key**:
This represents the top-level node-attribute you might be trying to override. In most attribute files, this is usually the name of the cookbook (`node['cookbook_name']`).

**first_override_hash_key**:
Looking at the override_file, this is the top-level hash key that we want reference, much like the node object, but in a JSON file, would be the top level JSON key (e.g. `overide_attributes['my_overrides']`).

**desired_hash_key**:
This represents the last key given in a hash reference.  The value of this key is what is returned by the method, whether that is a string or integer, or just more sub-hash to process. For example, if you're attempting to reference `node['my_cookbook']['registry_keys']['enable_lua']`, then you would want this value to be `enable_lua`.

**override_file**:
This is the full path and filename that has your override values you want to assess.  This is an optional value, but if a value is not given, then a default will be used.  The default value on Windows systems is `c:\chef\overrides.json`.  The default value on non-Windows systems is `/etc/chef/overrides.json`

#### Example

**Load an enable_LUA override directly into a registry_key resource**:

```ruby
registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
  values [{ name: 'EnableLUA',
            type: :dword,
            data:  get_override_file_value('my_cookbook', 'overrides', 'enable_lua', 'C:\cis_override.yml')
          }]
  action :create
end
```

If an `enable_lua` value exists in the override file, that will be used, otherwise it will use the default value defined in the node object.

### find_hash_value(hash, key)

This method is used to search a hash and return the value of the given key, even if that key is deep in the hash.

### merge_override_hash(hash_src, hash_dest)

This method is used to merge two hashes.  The `hash_src` is the source (or override) hash object, while the `hash_dst` is the hash object that you are merging into.  If a hash key (or chain of keys) in the source matches the destination, then the values of those keys in the destination will be overwritten.

**Danger!** If you set the destination hash to the `node` object, it will overwrite the node object starting at the hash destination key given. If you don't want to overwite your node object completely, then you should probably use one of the other methods here.
