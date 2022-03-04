module ChefMagic
  module UserUtils
    def get_users
      user_hash = {}
      File.open('/etc/passwd') do |passwd|
        passwd.each_line do |line|
          line.chomp!
          line.scan(/^(\w+):(.+):(\d+):(\d+):(.*):(.+):(.+)$/) do |usr, pass, uid, gid, name, home, shell|
            user_hash[usr] = { password: pass, uid: uid, gid: gid, name: name, homedir: home, shell: shell }
          end
        end
      end
      user_hash
    end

    def get_users_by_name(name, user_hash = get_users)
      sftp_users = {}

      user_hash.each do |user, info|
        next unless info[:name] == name
        sftp_users[user] = info
      end

      sftp_users
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::UserUtils
