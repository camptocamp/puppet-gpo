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

        if path.nil?
            warn "Unkown path for gpo resource: '#{split_g[1]}/#{split_g[2]}'"
            next
        end

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

  def out_line(scope, key, value_name, value)
      "#{scope}\n#{key}\n#{value_name}\n#{value}"
  end

  # Convert lgpo_import.txt to lgpo_import.pol with lgpo.exe
  def convert_to_pol(file)
      pol_file = File.basename(file, '.txt') + '.pol'
      lgpo_args = ['/r', file, '/w', pol_file]
      lgpo(*lgpo_args)
      File.delete(file)
      pol_file
  end

  # import lgpo_import.pol with lgpo.exe
  def import_pol(file, scope, guid)
    lgpo_args = ["/#{scope[0]}", file]
    lgpo_args << '/e' << guid if guid
    lgpo(*lgpo_args)
    File.delete(file)
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

    out = Array.new
    if setting_valuetype == '[HASHTABLE]'
        if val == 'DELETE'
            out << out_line(out_scope, path['setting_key'], '*', 'DELETEALLVALUES')
        else
            val.each do |k, v|
                out << out_line(out_scope, path['setting_key'], k, "SZ: #{v}")
            end
        end
    else
        val = "#{path['setting_valuetype'].gsub('REG_', '')}:#{val}" unless val == 'DELETE'
        out << out_line(out_scope, path['setting_key'], path['setting_valuename'], val)
    end

    out_file_path = File.join(Puppet[:vardir], 'lgpo_import.txt')
    File.open(out_file_path, 'w') do |out_file|
      out_file.write(out.join("\n\n"))
    end

    guid = path['policy_cse']
    remove_key(path['setting_key'], scope, guid) if setting_valuetype == '[HASHTABLE]'

    out_polfile_path = convert_to_pol(out_file_path)

    if setting_valuetype == '[HASHTABLE]'
        pol_file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
        File.delete(pol_file) if File.file?(pol_file)
    end

    import_pol(out_polfile_path, scope, guid)
  end

  def remove_key(key, scope, guid)
    pol_file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
    return unless File.file?(pol_file)

    out_file = File.join(Puppet[:vardir], 'lgpo_import.txt')
    gpos = lgpo('/parse', '/q', "/#{scope[0]}", pol_file)
    # Parse file and remove key
    new_gpos = gpos.split("\n\n").reject { |l| l.start_with? ';' }
                   .reject{ |l| l.split("\n")[1] == key }
    File.write(out_file, new_gpos.join("\n\n"))

    pol_file = convert_to_pol(out_file)
    import_pol(pol_file, scope, guid)
  end
end
