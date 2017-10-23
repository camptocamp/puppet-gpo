require 'spec_helper'

describe Puppet::Type.type(:gpo) do
    let(:validpath) {
        'machine::windowsupdate::windowsupdateserver'
    }

    context 'when validating path' do
        it 'should have path as namevar' do
            expect(described_class.key_attributes).to eq([:path])
        end

        it 'should accept a valid path' do
            res = described_class.new(:path => validpath)
            expect(res[:path]).to eq(validpath)
        end

        it 'should fail with an invalid path' do
            expect {
                described_class.new(:path => 'foo')
            }.to raise_error(Puppet::Error, /Wrong path: 'foo'/)
        end
    end

    context 'when validating ensure' do
        it 'should be ensurable' do
            expect(described_class.attrtype(:ensure)).to eq(:property)
        end

        it 'should be ensured to present by default' do
            res = described_class.new(:path => validpath)
            expect(res[:ensure]).to eq(:present)
        end

        it 'should be ensurable to absent' do
            res = described_class.new(
                :path => validpath,
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
                    :path  => validpath,
                    :value => 'foo',
                )
                expect(res[:value]).to eq('foo')
            end

            it 'should fail with a boolean' do
                expect {
                    described_class.new(
                        :path  => validpath,
                        :value => true,
                    )
                }.to raise_error(Puppet::Error, /Value should be a string, not 'true'/)
            end
        end
    end
end
