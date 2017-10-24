require 'spec_helper'

describe Puppet::Type.type(:gpo).provider(:lgpo) do
    let(:params) do
        {
            :title    => 'windowsupdate::autoupdatecfg::allowmuupdateservice',
            :value    => '1',
            :provider => 'lgpo',
        }
    end

    let(:resource) do
        Puppet::Type.type(:gpo).new(params)
    end

    let(:provider) do
        resource.provider
    end

    context 'when listing instances' do
        it 'should list instances' do
            provider.class.expects(:lgpo).once.with('/parse', '/q', '/m', 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol').returns(File.read(File.join(File.dirname(__FILE__), '../../../../fixtures/unit/puppet/provider/gpo/lgpo/machine/full.out')))
            provider.class.expects(:lgpo).once.with('/parse', '/q', '/u', 'C:\Windows\System32\GroupPolicy\User\Registry.pol').returns(File.read(File.join(File.dirname(__FILE__), '../../../../fixtures/unit/puppet/provider/gpo/lgpo/user/full.out')))
            instances = provider.class.instances.map do |i|
                {
                    :title             => i.get(:title),
                    :ensure            => i.get(:ensure),
                    :scope             => i.get(:scope),
                    :admx_file         => i.get(:admx_file),
                    :policy_id         => i.get(:policy_id),
                    :setting_valuename => i.get(:setting_valuename),
                    :value             => i.get(:value),
                }
            end
            expect(instances.size).to eq(17)
            expect(instances[0]).to eq({
                :title             => 'machine::credui::enumerateadministrators::enumerateadministrators',
                :ensure            => :present,
                :scope             => :machine,
                :admx_file         => 'credui',
                :policy_id         => 'enumerateadministrators',
                :setting_valuename => 'enumerateadministrators',
                :value             => '0',
            })
            expect(instances[4]).to eq({
                :title             => 'machine::inetres::disableactivexfirstprompt::nofirsttimeprompt',
                :ensure            => :absent,
                :scope             => :machine,
                :admx_file         => 'inetres',
                :policy_id         => 'disableactivexfirstprompt',
                :setting_valuename => 'nofirsttimeprompt',
                :value             => :absent,
            })
            expect(instances[15]).to eq({
                :title             => 'user::wpn::nolockscreentoastnotification::notoastapplicationnotificationonlockscreen',
                :ensure            => :present,
                :scope             => :user,
                :admx_file         => 'wpn',
                :policy_id         => 'nolockscreentoastnotification',
                :setting_valuename => 'notoastapplicationnotificationonlockscreen',
                :value             => '1',
            })
        end
    end
end
