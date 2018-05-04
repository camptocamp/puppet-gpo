Puppet::Type.type(:gpo).provide(:lgpo) do
  defaultfor :osfamily => :windows
  confine :osfamily => :windows

  commands :lgpo => 'lgpo.exe'

  def exists?
    @property_hash[:ensure] == :present
  end

  def deleted?
    @property_hash[:ensure] == :deleted
  end

  def create
    set_value(resource[:value])
    @property_hash[:ensure] = :present
  end

  def destroy
    delete
    # TODO: make system forget about key
    @property_hash[:ensure] = :absent
  end

  def delete
    set_value('DELETE')
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
        res[:scope].downcase == gpo.get(:scope).downcase &&
        res[:admx_file].downcase == gpo.get(:admx_file).downcase &&
        res[:policy_id].downcase == gpo.get(:policy_id).downcase &&
        res[:setting_valuename].downcase == gpo.get(:setting_valuename).downcase
      }.map { |name, res|
        res.provider = gpo
      }
    end
  end

  def self.instances
    paths = PuppetX::Gpo::Paths.new

    ['machine', 'user'].map do |scope|
      pol_file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
      next [] unless File.file?(pol_file)

      resources = Hash.new

      gpos = lgpo('/parse', '/q', "/#{scope[0]}", pol_file)
      gpos.split("\n\n").reject { |l| l.start_with? ';' }.map do |g|
        split_g = g.split("\n")
        path = paths.get_by_key(scope, split_g[1].downcase, split_g[2].downcase)

        admx_file = path['admx_file'].downcase
        policy_id = path['policy_id'].downcase
        setting_valuename = path['setting_valuename'].downcase
        setting_valuetype = path['setting_valuetype']
        value = split_g[3].split(':')[1]
        name = "#{scope}::#{admx_file}::#{policy_id}::#{setting_valuename}"

        if setting_valuetype == '[HASHTABLE]'
          hash_value = {split_g[2] => value}
          if resources.has_key?(name)
            resources[name][:value].merge!(hash_value)
          else
            resources[name] = {
              :name              => name,
              :ensure            => split_g[3] == 'DELETEALLVALUES' ? :deleted : :present,
              :scope             => scope.to_sym,
              :admx_file         => admx_file,
              :policy_id         => policy_id,
              :setting_valuename => setting_valuename,
              :value             => split_g[3] == 'DELETEALLVALUES' ? :absent : hash_value,
            }
          end
        else
          resources[name] = {
            :name              => name,
            :ensure            => split_g[3] == 'DELETE' ? :deleted : :present,
            :scope             => scope.to_sym,
            :admx_file         => admx_file,
            :policy_id         => policy_id,
            :setting_valuename => setting_valuename,
            :value             => value,
          }
        end

      end
      resources.map{|k, v| new(v)}
    end.flatten
  end

  def set_value(val)
    scope = resource[:scope].to_s
    admx_file = resource[:admx_file]
    policy_id = resource[:policy_id]
    setting_valuename = resource[:setting_valuename]
    path = PuppetX::Gpo::Paths.new.get_item(scope, admx_file, policy_id, setting_valuename)
    setting_valuetype = path['setting_valuetype']

    if path.nil?
      raise Puppet::Error, "Wrong path: '#{path}'"
    end

    out_scope = (scope == 'machine' ? 'computer' : scope).capitalize
    delete_value = setting_valuetype == '[HASHTABLE]' ? 'DELETEALLVALUES' : 'DELETE'

    out = Array.new
    if setting_valuetype == '[HASHTABLE]' and val != 'DELETE'
      val.each do |k, v|
        out << "#{out_scope}\n#{path['setting_key']}\n#{k}\nSZ:#{v}"
      end
    else
      real_val = val == 'DELETE' ? delete_value : "#{path['setting_valuetype'].gsub('REG_', '')}:#{val}"
      setting_valuename = real_val == 'DELETEALLVALUES' ? '*' : path['setting_valuename']

      out << "#{out_scope}\n#{path['setting_key']}\n#{setting_valuename}\n#{real_val}"

    end

    out_file_path = File.join(Puppet[:vardir], 'lgpo_import.txt')
    out_polfile_path = File.join(Puppet[:vardir], 'lgpo_import.pol')
    File.open(out_file_path, 'w') do |out_file|
      out_file.write(out.join("\n\n"))
    end

    remove_key(path['setting_key'], scope) if setting_valuetype == '[HASHTABLE]'

    # Convert lgpo_import.txt to lgpo_import.pol with lgpo.exe
    lgpo_args = ['/r', out_file_path, '/w', out_polfile_path]
    lgpo(*lgpo_args)
    File.delete(out_file_path)

    if setting_valuetype == '[HASHTABLE]'
        pol_file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
        File.delete(pol_file)
    end

    # import lgpo_import.pol with lgpo.exe
    lgpo_args = ["/#{scope[0]}", out_polfile_path]
    if guid = path['policy_cse']
      lgpo_args << '/e' << guid
    end
    lgpo(*lgpo_args)
    File.delete(out_polfile_path)
  end

  def remove_key(key, scope)
    pol_file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
    return [] unless File.file?(pol_file)
    out_file_path = File.join(Puppet[:vardir], 'lgpo_import.txt')
    gpos = lgpo('/parse', '/q', "/#{scope[0]}", pol_file)
    File.open(out_file_path, 'a') do |out_file|
      gpos.split("\n\n").reject { |l| l.start_with? ';' }.each do |g|
        split_g = g.split("\n")
        unless split_g[1] == key
          out_file.write("\n\n#{g}")
        end
      end
    end
  end
end
