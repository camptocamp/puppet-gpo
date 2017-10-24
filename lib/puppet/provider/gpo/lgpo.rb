Puppet::Type.type(:gpo).provide(:lgpo) do
  defaultfor :osfamily => :windows
  confine :osfamily => :windows

  commands :lgpo => 'lgpo.exe'

  def exists?

  end

  def create

  end

  def destroy

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
                  :ensure            => split_g[3] == 'DELETE' ? :absent : :present,
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
