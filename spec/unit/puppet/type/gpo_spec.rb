require 'spec_helper'

describe Puppet::Type.type(:gpo) do
    let(:valid_string_path) {
        'windowsupdate::autoupdatecfg::allowmuupdateservice'
    }

    let(:valid_hash_path) {
        'advancedfirewall::wf_firewallrules::firewallrules'
    }

    context 'when using namevar' do
        it 'should have namevars' do
            expect(described_class.key_attributes).to eq([:path, :admx_file, :policy_id, :setting_valuename])
        end

        it 'should accept a composite namevar' do
            res = described_class.new(:title => valid_string_path)
            expect(res[:admx_file]).to eq('windowsupdate')
            expect(res[:policy_id]).to eq('autoupdatecfg')
            expect(res[:setting_valuename]).to eq('allowmuupdateservice')
        end
    end

    context 'when validating path' do
        it 'should accept a valid path' do
            res = described_class.new(:title => valid_string_path)
            expect(res[:path]).to eq(valid_string_path)
        end

        it 'should fail with an invalid path' do
            expect {
                described_class.new(:title => 'foo')
            }.to raise_error(Puppet::Error, /Wrong path: 'foo'/)
        end
    end

    context 'when validating ensure' do
        it 'should be ensurable' do
            expect(described_class.attrtype(:ensure)).to eq(:property)
        end

        it 'should be ensured to present by default' do
            res = described_class.new(:title => valid_string_path)
            expect(res[:ensure]).to eq(:present)
        end

        it 'should be ensurable to absent' do
            res = described_class.new(
                :title  => valid_string_path,
                :ensure => :absent
            )
            expect(res[:ensure]).to eq(:absent)
        end
    end

    context 'when validating value' do
        it 'should have a value property' do
            expect(described_class.attrtype(:value)).to eq(:property)
        end

        context 'when expecting a string' do
            it 'should accept a string' do
                res = described_class.new(
                    :title => valid_string_path,
                    :value => 'foo',
                )
                expect(res[:value]).to eq('foo')
            end

            it 'should fail with a boolean' do
                expect {
                    described_class.new(
                        :title => valid_string_path,
                        :value => true,
                    )
                }.to raise_error(Puppet::Error, /Value should be a string, not 'true'/)
            end
        end

        context 'when expecting a hash' do
            it 'should accept a hash' do
                res = described_class.new(
                    :title => valid_hash_path,
                    :value => { 'foo' => 'bar' },
                )
                expect(res[:value]).to eq({'foo' => 'bar'})
            end

            it 'should fail with a string' do
                expect {
                    described_class.new(
                        :title => valid_hash_path,
                        :value => 'foo',
                    )
                }.to raise_error(Puppet::Error, /Value should be a hash, not 'foo'/)
            end
        end
    end
end
