require 'spec_helper'

describe 'openscap::schedule' do

  base_facts = {
    :operatingsystemmajrelease => '7'
  }
  let(:facts){base_facts}

  context 'base' do
    it { should compile.with_all_deps }
    it { should create_file('/var/log/openscap').with_ensure('directory') }
  end
end
