require 'spec_helper'

describe 'openscap' do

  it { should create_class('openscap') }

  context 'base' do
    it { should compile.with_all_deps }
    it { should contain_package('openscap-utils') }
    it { should contain_package('scap-security-guide') }
  end
end
