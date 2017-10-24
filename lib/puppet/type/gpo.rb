require 'puppet_x/gpo'

Puppet::Type.newtype(:gpo) do
    ensurable do
        defaultvalues
        defaultto(:present)
    end

    newparam(:path, :namevar => true) do
    end

    newparam(:scope, :namevar => true) do
        newvalues(:user, :machine)
        defaultto(:machine)

        munge do |val|
            val.downcase.to_sym
        end
    end

    newparam(:admx_file, :namevar => true) do
        munge do |val|
            val.downcase
        end
    end

    newparam(:policy_id, :namevar => true) do
        munge do |val|
            val.downcase
        end
    end

    newparam(:setting_valuename, :namevar => true) do
        munge do |val|
            val.downcase
        end

        validate do |val|
            scope = (resource[:scope] || :machine).to_s   # defaults get computed after validation
            path = resource[:path] || "#{scope}::#{resource[:admx_file]}::#{resource[:policy_id]}::#{val}"
            if PuppetX::Gpo.new.get_item(
                    scope,
                    resource[:admx_file],
                    resource[:policy_id],
                    val
            ).nil?
                raise Puppet::Error, "Wrong path: '#{path}'"
            end
        end
    end

    def self.title_patterns
        identity = lambda { |x| x.downcase }
        [
            [
                /^(([^:]+)::([^:]+)::([^:]+)::([^:]+))$/,
                [
                    [ :path, identity ],
                    [ :scope, identity ],
                    [ :admx_file, identity ],
                    [ :policy_id, identity ],
                    [ :setting_valuename, identity ],
                ]
            ],
            [
                /^(([^:]+)::([^:]+)::([^:]+))$/,
                [
                    [ :path, identity ],
                    [ :admx_file, identity ],
                    [ :policy_id, identity ],
                    [ :setting_valuename, identity ],
                ]
            ],
            [
                /(.*)/,
                [
                    [ :path, identity ],
                ]
            ]
        ]
    end

    newproperty(:value) do
        validate do |val|
            scope = (resource[:scope] || :machine).to_s   # defaults get computed after validation
            path = resource[:path] || "#{scope}::#{resource[:admx_file]}::#{resource[:policy_id]}::#{resource[:setting_valuename]}"

            k = PuppetX::Gpo.new.get_item(
                scope,
                resource[:admx_file],
                resource[:policy_id],
                resource[:setting_valuename]
            )
            if k.nil?
                raise Puppet::Error, "Wrong path: '#{path}'"
            end

            case k['setting_valuetype']
            when 'REG_DWORD', 'REG_SZ', 'REG_MULTI_SZ'
                raise Puppet::Error, _("Value should be a string, not '#{val}'") unless val.is_a? String
            when '[HASHTABLE]'
                raise Puppet::Error, _("Value should be a hash, not '#{val}'") unless val.is_a? Hash
            else
                raise Puppet::Error, _("Unknown type '#{k['type']}'")
            end
        end
    end
end
