require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'openscap::schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        base_facts = facts.merge({:spec_title => description})

        describe 'base' do
          let(:facts) { base_facts }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('openscap::schedule') }
          it { is_expected.to create_class('openscap') }

          it { is_expected.to create_file('/var/log/openscap') }
          it { is_expected.to create_cron('openscap') }
        end

        describe 'with logrotate => true' do
          let(:facts) { base_facts}
          let(:params) {{ :logrotate => true }}

          it { is_expected.to create_class('logrotate') }
          it { is_expected.to create_logrotate__rule('openscap') }

          if ['RedHat','CentOS'].include?(facts[:operatingsystem])
            if facts[:operatingsystemmajrelease].to_s < '7'
              it { should create_file('/etc/logrotate.d/openscap').with_content(/#{file_content_6}/)}
            else
              it { should create_file('/etc/logrotate.d/openscap').with_content(/#{file_content_7}/)}
            end
          end

        end
      end
    end
  end
end
