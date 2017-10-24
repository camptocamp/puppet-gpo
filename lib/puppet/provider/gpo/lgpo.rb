Puppet::Type.type(:gpo).provide(:lgpo) do
  defaultfor :osfamily => :windows
  confine :osfamily => :windows

  commands :lgpo => 'lgpo.exe'

  def exists?
      @property_hash[:ensure] == :present
  end

  def create
      # create temp file and apply it
  end

  def destroy
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
