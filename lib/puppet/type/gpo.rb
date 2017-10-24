require 'puppet_x/gpo'

Puppet::Type.newtype(:gpo) do
    ensurable do
        defaultvalues
        defaultto(:present)
    end

    newparam(:path, :namevar => true) do
        munge do |val|
            val.downcase
        end

        validate do |val|
            if PuppetX::Gpo.new.item_by_path(val).nil?
                raise Puppet::Error, _("Wrong path: '#{val}'")
            end
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
    end

    def self.title_patterns
        identity = lambda { |x| x }
        [
            [
                /^((\S+)::(\S+)::(\S+))$/,
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
            k = PuppetX::Gpo.new.item_by_path(@resource[:path])
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
