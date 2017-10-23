require 'puppet_x/gpo'

Puppet::Type.newtype(:gpo) do
    ensurable do
        defaultvalues
        defaultto(:present)
    end

    newparam(:path, :namevar => true) do
        validate do |val|
            unless PuppetX::Gpo.new.valid_paths.has_key? val
                raise Puppet::Error, _("Wrong path: '#{val}'")
            end
        end
    end

    newproperty(:value) do
        validate do |val|
            k = PuppetX::Gpo.new.valid_paths[@resource[:path]]
            case k['type']
            when 'DWORD'
                raise Puppet::Error, _("Value should be a string, not '#{val}'") unless val.is_a? String
            else
                raise Puppet::Error, _("Unknown type '#{k['type']}'")
            end
        end
    end
end
