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

    end
end
