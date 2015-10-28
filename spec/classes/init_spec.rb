require 'spec_helper'

describe 'openscap' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('openscap') }
        
        context 'base' do
          it { is_expected.to contain_package('openscap-utils').with( :ensure => 'latest') }
          it { is_expected.to contain_package('scap-security-guide').with( :ensure => 'latest') }
        end
      end
    end
  end
end
