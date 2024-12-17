require 'spec_helper'

describe 'Openscap::Profile' do
  it { is_expected.to allow_values('xccdf_org.ssgproject.content_profile_rht-ccp', 'xccdf_org.ssgproject.content_profile_stig-rhel7-disa') }

  it { is_expected.not_to allow_values('test_profile_rhel', 'xccdf_org.test_profile') }
end
