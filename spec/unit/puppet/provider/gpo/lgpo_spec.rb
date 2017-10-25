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

    let(:vardir) do
      'C:\ProgramData\PuppetLabs\Puppet\var'
    end

    let(:out_file) do
        File.join(vardir, '/lgpo_import.txt')
    end

    let(:out_polfile) do
        File.join(vardir, '/lgpo_import.pol')
    end

    def stub_lgpo_pol(scope, present)
        file = "C:\\Windows\\System32\\GroupPolicy\\#{scope.capitalize}\\Registry.pol"
        allow(File).to receive(:file?)   # Catch all calls
        expect(File).to receive(:file?).once.with(file).and_return(present)

        if present
            provider.class.expects(:lgpo).once.with('/parse', '/q', "/#{scope[0]}", file)
                .returns(File.read(File.join(
            File.dirname(__FILE__),
            "../../../../fixtures/unit/puppet/provider/gpo/lgpo/#{scope}/full.out")))
        else
            provider.class.expects(:lgpo).never
        end
    end

    def stub_create(scope, content, cse)
        file = StringIO.new
        expect(File).to receive(:open).once.with(out_file, 'w').and_yield(file)
        expect(file).to receive(:write).with(content)

        args = ["/r", out_file]
        args << '/w' << out_polfile
        provider.class.expects(:lgpo).once.with(*args).returns(nil)
        expect(File).to receive(:delete).once.with(out_file).and_return(nil)

        args = ["/#{scope[0]}", out_polfile]
        args << '/e' << cse unless cse.nil?
        provider.class.expects(:lgpo).once.with(*args).returns(nil)
        expect(File).to receive(:delete).once.with(out_polfile).and_return(nil)
    end

    context 'when listing instances' do
        context 'when the gpo file exists' do
            it 'should list instances' do
                stub_lgpo_pol('machine', true)
                stub_lgpo_pol('user', true)

                instances = provider.class.instances.map do |i|
                    {
                        :name              => i.get(:name),
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
                    :name              => 'machine::credui::enumerateadministrators::enumerateadministrators',
                    :ensure            => :present,
                    :scope             => :machine,
                    :admx_file         => 'credui',
                    :policy_id         => 'enumerateadministrators',
                    :setting_valuename => 'enumerateadministrators',
                    :value             => '0',
                })
                expect(instances[4]).to eq({
                    :name              => 'machine::inetres::disableactivexfirstprompt::nofirsttimeprompt',
                    :ensure            => :deleted,
                    :scope             => :machine,
                    :admx_file         => 'inetres',
                    :policy_id         => 'disableactivexfirstprompt',
                    :setting_valuename => 'nofirsttimeprompt',
                    :value             => :absent,
                })
                expect(instances[15]).to eq({
                    :name              => 'user::wpn::nolockscreentoastnotification::notoastapplicationnotificationonlockscreen',
                    :ensure            => :present,
                    :scope             => :user,
                    :admx_file         => 'wpn',
                    :policy_id         => 'nolockscreentoastnotification',
                    :setting_valuename => 'notoastapplicationnotificationonlockscreen',
                    :value             => '1',
                })
            end
        end

        context 'when the gpo file does not exist' do
            it 'should return no instances' do
                stub_lgpo_pol('machine', false)
                stub_lgpo_pol('user', false)

                instances = provider.class.instances
                expect(instances.size).to eq(0)
            end
        end
    end

    context 'when prefetching resources' do
        it 'should call self.instances' do
            expect(provider.class).to receive(:instances).and_return([])
            provider.class.prefetch([])
        end

        it 'should find existing resources' do
            stub_lgpo_pol('machine', true)
            stub_lgpo_pol('user', true)

            fake_res = {
                :name              => 'machine::inetres::disableactivexfirstprompt::nofirsttimeprompt',
                :ensure            => 'present',
                :scope             => :machine,
                :admx_file         => 'inetres',
                :policy_id         => 'disableactivexfirstprompt',
                :setting_valuename => 'nofirsttimeprompt',
                :value             => '1',
            }

            expect(fake_res).to receive(:provider=)
            provider.class.prefetch({ 'machine::inetres::disableactivexfirstprompt::nofirsttimeprompt' => fake_res })
        end
    end

    context 'when creating a resource' do
        before :each do
            expect(Puppet).to receive(:[]).twice.with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
        end

        context 'when there is no cse' do
            it 'should create a resource without /e' do
                stub_create('machine', "computer\nSoftware\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\nAllowMUUpdateService\nDWORD:1", nil)

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
                stub_create('machine', "computer\nSoftware\\Policies\\Microsoft Services\\AdmPwd\nAdmPwdEnabled\nDWORD:1", '{D76B9641-3288-4f75-942D-087DE603E3EA}')

                provider.create
            end
        end
    end

    context 'when deleting a resource' do
        before :each do
            expect(Puppet).to receive(:[]).twice.with(:vardir).and_return('C:\ProgramData\PuppetLabs\Puppet\var')
        end

        context 'when there is no cse' do
            it 'should create a resource without /e' do
                stub_create('machine', "computer\nSoftware\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU\nAllowMUUpdateService\nDELETE", nil)

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
                stub_create('machine', "computer\nSoftware\\Policies\\Microsoft Services\\AdmPwd\nAdmPwdEnabled\nDELETE", '{D76B9641-3288-4f75-942D-087DE603E3EA}')

                provider.delete
            end
        end
    end
end
