module ChefMagic
  module FileUtils
    def get_mode(path)
      File.stat(path).mode.to_s(8).split('')[-4..-1].join
    end

    def modified_world_mode(mode, world)
      mode_s = mode.to_s
      world_s = world.to_s
      mode_s.gsub(/[0-9]$/, world_s)
    end

    def modified_group_mode(mode, group)
      mode_s = mode.to_s
      group_s = group.to_s
      mode_s.gsub(/[0-9]?$/, group_s)
    end

    def modified_owner_mode(mode, owner)
      mode_s = mode.to_s
      owner_s = owner.to_s
      mode_s.gsub(/[0-9]??$/, owner_s)
    end
  end
end

Chef::DSL::Universal.include ::ChefMagic::FileUtils
