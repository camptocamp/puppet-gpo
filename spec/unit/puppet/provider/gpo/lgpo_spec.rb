require 'spec_helper'
require 'stringio'

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
            provider.class.expects(:lgpo).once.with(
                '/parse', '/q', '/m', 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol'
            ).returns(File.read(File.join(
                File.dirname(__FILE__),
                '../../../../fixtures/unit/puppet/provider/gpo/lgpo/machine/full.out')))
            provider.class.expects(:lgpo).once.with(
                '/parse', '/q', '/u', 'C:\Windows\System32\GroupPolicy\User\Registry.pol'
            ).returns(File.read(File.join(
                File.dirname(__FILE__),
                '../../../../fixtures/unit/puppet/provider/gpo/lgpo/user/full.out')))
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
                :ensure            => :deleted,
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

    context 'when creating a resource' do
        context 'when there is no cse' do
            it 'should create a resource without /e' do
                expect(Puppet).to receive(:[]).with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
                out_file = 'C:\ProgramData\PuppetLabs\Puppet\var/lgpo_import.txt'
                file = StringIO.new
                expect(File).to receive(:open).once.with(out_file, 'w').and_yield(file)
                expect(file).to receive(:write).with("computer\nSoftware\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\nsetting_valuename\nDWORD:1")
                provider.class.expects(:lgpo).once.with(
                    '/m', out_file,
                ).returns(nil)
                expect(File).to receive(:delete).once.with(out_file).and_return(nil)

                provider.create
            end
        end

        context 'when there is a cse' do
            let(:params) do
                {
                    :title    => 'admpwd::pol_admpwd_enabled::admpwdenabled',
                    :value    => '1',
                    :provider => 'lgpo',
                }
            end

            it 'should create a resource with /e' do
                expect(Puppet).to receive(:[]).with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
                out_file = 'C:\ProgramData\PuppetLabs\Puppet\var/lgpo_import.txt'

                file = StringIO.new
                expect(File).to receive(:open).once.with(out_file, 'w').and_yield(file)
                expect(file).to receive(:write).with("computer\nSoftware\\Policies\\Microsoft Services\\AdmPwd\nsetting_valuename\nDWORD:1")

                provider.class.expects(:lgpo).once.with(
                    '/m', out_file,
                    '/e', '{D76B9641-3288-4f75-942D-087DE603E3EA}'
                ).returns(nil)
                expect(File).to receive(:delete).once.with(out_file).and_return(nil)

                provider.create
            end
        end
    end

    context 'when deleting a resource' do
        context 'when there is no cse' do
            it 'should create a resource without /e' do
                expect(Puppet).to receive(:[]).with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
                out_file = 'C:\ProgramData\PuppetLabs\Puppet\var/lgpo_import.txt'
                file = StringIO.new
                expect(File).to receive(:open).once.with(out_file, 'w').and_yield(file)
                expect(file).to receive(:write).with("computer\nSoftware\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\nsetting_valuename\nDELETE")
                provider.class.expects(:lgpo).once.with(
                    '/m', out_file,
                ).returns(nil)
                expect(File).to receive(:delete).once.with(out_file).and_return(nil)

                provider.delete
            end
        end

        context 'when there is a cse' do
            let(:params) do
                {
                    :title    => 'admpwd::pol_admpwd_enabled::admpwdenabled',
                    :value    => '1',
                    :provider => 'lgpo',
                }
            end

            it 'should create a resource with /e' do
                expect(Puppet).to receive(:[]).with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
                out_file = 'C:\ProgramData\PuppetLabs\Puppet\var/lgpo_import.txt'

                file = StringIO.new
                expect(File).to receive(:open).once.with(out_file, 'w').and_yield(file)
                expect(file).to receive(:write).with("computer\nSoftware\\Policies\\Microsoft Services\\AdmPwd\nsetting_valuename\nDELETE")

                provider.class.expects(:lgpo).once.with(
                    '/m', out_file,
                    '/e', '{D76B9641-3288-4f75-942D-087DE603E3EA}'
                ).returns(nil)
                expect(File).to receive(:delete).once.with(out_file).and_return(nil)

                provider.delete
            end
        end
    end
end
