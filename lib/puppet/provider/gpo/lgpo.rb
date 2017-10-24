Puppet::Type.type(:gpo).provide(:lgpo) do
  defaultfor :osfamily => :windows
  confine :osfamily => :windows

  commands :lgpo => 'lgpo.exe'

  def exists?
      @property_hash[:ensure] == :present
  end

  def create
      scope = resource[:scope].to_s
      admx_file = resource[:admx_file]
      policy_id = resource[:policy_id]
      setting_valuename = resource[:setting_valuename]
      value = resource[:value]
      path = PuppetX::Gpo::Paths.new.get_item(scope, admx_file, policy_id, setting_valuename)

      if path.nil?
          raise Puppet::Error, "Wrong path: '#{path}'"
      end

      out_scope = scope == 'machine' ? 'computer' : scope
      out = "#{out_scope}\n#{path['setting_key']}\n#{'setting_valuename'}\n#{path['setting_valuetype'].gsub('REG_', '')}:#{value}"

      out_file_path = File.join(Puppet[:vardir], 'lgpo_import.txt')
      File.open(out_file_path, 'w') do |out_file|
          out_file.write(out)
      end

      lgpo_args = ["/#{scope[0]}", out_file_path]
      if guid = path['policy_cse']
          lgpo_args << '/e' << guid
      end
      lgpo(*lgpo_args)
      File.delete(out_file_path)

      @property_hash[:ensure] = :present
  end

  def destroy
      delete
      # TODO: make system forget about key
      @property_hash[:ensure] = :absent
  end

  def delete
      # TODO: delete resource
      @property_hash[:ensure] = :deleted
  end

  def value
      @property_hash[:value]
  end

  def value=(val)
      create
  end

  def self.prefetch(resources)
      instances.each do |gpo|
          resources.select { |title, res|
              res[:scope].downcase == gpo[:scope].downcase &&
                  res[:admx_file].downcase == gpo[:admx_file].downcase &&
                  res[:policy_id].downcase == gpo[:policy_id].downcase &&
                  res[:setting_valuename].downcase == gpo[:setting_valuename].downcase
          }.map { |name, res|
              res.provider = gpo
          }
      end
  end

  def self.instances
      paths = PuppetX::Gpo::Paths.new

      ['machine', 'user'].map do |scope|
          gpos = lgpo('/parse', '/q', "/#{scope[0]}", "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol")
          gpos.split("\n\n").reject { |l| l.start_with? ';' }.map do |g|
              split_g = g.split("\n")
              path = paths.get_by_key(scope, split_g[1].downcase, split_g[2].downcase)

              admx_file = path['admx_file'].downcase
              policy_id = path['policy_id'].downcase
              setting_valuename = path['setting_valuename'].downcase
              value = split_g[3].split(':')[1]

              new({
                  :title             => "#{scope}::#{admx_file}::#{policy_id}::#{setting_valuename}",
                  :ensure            => split_g[3] == 'DELETE' ? :deleted : :present,
                  :scope             => scope.to_sym,
                  :admx_file         => admx_file,
                  :policy_id         => policy_id,
                  :setting_valuename => setting_valuename,
                  :value             => value,
              })
          end
      end.flatten
  end
end
