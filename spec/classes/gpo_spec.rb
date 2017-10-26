require 'spec_helper'

describe 'gpo' do
  context 'when called without parameters' do
      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_package('lgpo')
          .with_provider('chocolatey')
      }
  end
end
