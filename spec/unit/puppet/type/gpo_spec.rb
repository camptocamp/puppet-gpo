require 'spec_helper'

describe Puppet::Type.type(:gpo) do
    context 'when validating namevar' do
        it 'should have path as namevar' do
            expect(described_class.key_attributes).to eq([:path])
        end
    end

    context 'when validating ensure' do
        it 'should be ensurable' do
            expect(described_class.attrtype(:ensure)).to eq(:property)
        end

        it 'should be ensured to present by default' do
            res = described_class.new(:path => 'foo')
            expect(res[:ensure]).to eq(:present)
        end

        it 'should be ensurable to absent' do
            res = described_class.new(:path => 'foo', :ensure => :absent)
            expect(res[:ensure]).to eq(:absent)
        end
    end

    context 'when validating value' do
        it 'should have a value property' do
            expect(described_class.attrtype(:value)).to eq(:property)
        end
    end
end
