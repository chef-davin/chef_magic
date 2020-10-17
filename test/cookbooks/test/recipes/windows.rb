registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
  values [{ name: 'EnableLUA',
            type: :dword,
            data:  get_override_file_value('my_cookbook', 'overrides', 'enable_lua', 'C:\cis_override.yml')
          }]
  action :create
end
