require 'spec_helper'

describe PuppetX::Gpo do
    let(:valid_paths_file) {
        File.realpath(File.join(File.dirname(__FILE__), '../../../lib/puppet_x/gpo/paths.json'))
    }

    before(:each) {
        PuppetX::Gpo.class_variable_set :@@valid_paths, nil
    }

    context 'when checking the valid_paths_file' do
        it 'should find json file in proper location' do
            expect(PuppetX::Gpo.new.valid_paths_file).to eq valid_paths_file
        end
    end

    context 'when calling valid_paths several times' do
        it 'should read file once' do
            expect(File).to receive(:read).once.with(valid_paths_file).and_return('{"foo":"bar"}')
            PuppetX::Gpo.new.valid_paths
            PuppetX::Gpo.new.valid_paths
        end
    end
end
