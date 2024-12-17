require 'spec_helper'

describe 'openscap' do
  on_supported_os.each do |os, facts|
    context "on #{os}", skip: ((os =~ %r{rocky}i) ? 'Rocky Linux does not currently have any officially supported ssg streams' : nil) do
      base_facts = facts.merge({ spec_title: description })

      describe 'base' do
        let(:facts) { base_facts }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('openscap') }

        it { is_expected.not_to create_class('openscap::schedule') }
        it { is_expected.to contain_package('openscap-utils').with(ensure: 'installed') }
        it { is_expected.to contain_package('scap-security-guide').with(ensure: 'installed') }
      end

      describe 'with enable_schedule=true' do
        let(:facts) { base_facts }
        let(:params) { { enable_schedule: true } }

        it { is_expected.to create_class('openscap::schedule') }
      end
    end
  end
end
