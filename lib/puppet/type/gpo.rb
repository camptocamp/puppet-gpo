require 'puppet_x/gpo/paths'

Puppet::Type.newtype(:gpo) do
    @doc = <<-'EOT'
    Apply a Windows local GPO.
    EOT

    ensurable do
        defaultvalues
        defaultto(:present)

        newvalue(:deleted) do
            provider.delete
        end

        def insync?(is)
            return true if should == :deleted and provider.deleted?
            super
        end
    end

    newparam(:name, :namevar => true) do
        desc 'The GPO name, used for uniqueness.'
    end

    newparam(:scope, :namevar => true) do
        desc 'The GPO scope.'

        newvalues(:user, :machine)
        defaultto(:machine)

        munge do |val|
            val.downcase.to_sym
        end
    end

    newparam(:admx_file, :namevar => true) do
        desc 'The GPO ADMX File.'

        munge do |val|
            val.downcase
        end
    end

    newparam(:policy_id, :namevar => true) do
        desc 'The GPO policy ID.'

        munge do |val|
            val.downcase
        end
    end

    newparam(:setting_valuename, :namevar => true) do
        desc 'The GPO setting value name.'

        munge do |val|
            val.downcase
        end

        validate do |val|
            scope = (resource[:scope] || :machine).to_s   # defaults get computed after validation
            name = resource[:name] || "#{scope}::#{resource[:admx_file]}::#{resource[:policy_id]}::#{val}"
            if PuppetX::Gpo::Paths.new.get_item(
                    scope,
                    resource[:admx_file],
                    resource[:policy_id],
                    val
            ).nil?
                raise Puppet::Error, "Not a valid path: '#{name}'"
            end
        end
    end

    def self.title_patterns
        identity = lambda { |x| x.downcase }
        [
            [
                /^(([^:]+)::([^:]+)::([^:]+)::([^:]+))$/,
                [
                    [ :name, identity ],
                    [ :scope, identity ],
                    [ :admx_file, identity ],
                    [ :policy_id, identity ],
                    [ :setting_valuename, identity ],
                ]
            ],
            [
                /^(([^:]+)::([^:]+)::([^:]+))$/,
                [
                    [ :name, identity ],
                    [ :admx_file, identity ],
                    [ :policy_id, identity ],
                    [ :setting_valuename, identity ],
                ]
            ],
            [
                /(.*)/,
                [
                    [ :name, identity ],
                ]
            ]
        ]
    end

    newproperty(:value) do
        desc 'The GPO value.'

        validate do |val|
            scope = (resource[:scope] || :machine).to_s   # defaults get computed after validation
            name = resource[:name] || "#{scope}::#{resource[:admx_file]}::#{resource[:policy_id]}::#{resource[:setting_valuename]}"

            k = PuppetX::Gpo::Paths.new.get_item(
                scope,
                resource[:admx_file],
                resource[:policy_id],
                resource[:setting_valuename]
            )
            if k.nil?
                raise Puppet::Error, "Not a valid path: '#{name}'"
            end

            case k['setting_valuetype']
            when 'REG_DWORD', 'REG_SZ', 'REG_MULTI_SZ'
                raise Puppet::Error, "Value should be a string, not '#{val}'" unless val.is_a? String
            when '[HASHTABLE]'
                raise Puppet::Error, "Value should be a hash, not '#{val}'" unless val.is_a? Hash
            else
                raise Puppet::Error, "Unknown type '#{k['type']}'"
            end
        end
    end
end
