Puppet::Type.newtype(:gpo) do
    ensurable do
        defaultvalues
        defaultto(:present)
    end

    newparam(:path, :namevar => true) do

    end

    newproperty(:value) do

    end
end
