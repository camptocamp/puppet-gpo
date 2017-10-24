require 'puppet_x/gpo'

Puppet::Type.newtype(:gpo) do
    ensurable do
        defaultvalues
        defaultto(:present)
    end

    newparam(:path, :namevar => true) do
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
            if PuppetX::Gpo.new.get_item(@resource[:admx_file], @resource[:policy_id], val).nil?
                raise Puppet::Error, "Wrong path: '#{@resource[:admx_file]}::#{@resource[:policy_id]}::#{val}'"
            end
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
            path = @resource[:path]
            path ||= "#{@resource[:admx_file]}::#{@resource[:policy_id]}::#{@resource[:setting_valuename]}"

            k = PuppetX::Gpo.new.get_item(
                @resource[:admx_file],
                @resource[:policy_id],
                @resource[:setting_valuename]
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
