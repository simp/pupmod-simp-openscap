require 'spec_helper'

describe 'openscap::schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      base_facts = {
        :operatingsystemmajrelease => '7'
      }
      let(:facts){base_facts}

      context "on #{os}"do
        it { is_expected.to compile.with_all_deps }
        
        context 'base' do
          it { is_expected.to create_file('/var/log/openscap').with_ensure('directory') }
        end
      end
    end
  end
end

