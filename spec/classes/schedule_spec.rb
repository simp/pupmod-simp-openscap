require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'openscap::schedule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|

      shared_examples 'a working module' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('openscap::schedule') }
        it { is_expected.to create_class('openscap') }

        it { is_expected.to create_file('/var/log/openscap') }
        it { is_expected.to create_cron('openscap') }
      end

      context "on #{os}" do
        context 'with a valid environment' do
          let(:facts) {
            oscap_fact = {
              :oscap => {
                'path' => '/bin/oscap',
                'version' => '1.2.16',
                'supported_specifications' => {
                  'XCCDF' => '1.2',
                  'OVAL' => '5.11.1'
                },
                'profiles' => {
                  '/usr/share/xml/scap/ssg/content' => {
                    "ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds" => {
                      'xccdf_org.ssgproject.content_profile_standard' => 'Standard System Security Profile'
                    }
                  }
                }
              }
            }

            os_facts.merge(oscap_fact)
          }

          let(:params) {{
            :scap_profile => 'xccdf_org.ssgproject.content_profile_standard',
            :ssg_data_stream => "ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds.xml"
          }}

          it_behaves_like 'a working module'

          context 'with logrotate => true' do
            let(:params) {{
              :scap_profile => 'xccdf_org.ssgproject.content_profile_standard',
              :ssg_data_stream => "ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds.xml",
              :logrotate => true
            }}

            it_behaves_like 'a working module'
            it { is_expected.to create_class('logrotate') }
            it { is_expected.to create_logrotate__rule('openscap') }

            if os_facts[:operatingsystemmajrelease].to_s < '7'
              it { is_expected.to create_file('/etc/logrotate.d/openscap').with_content(/#{file_content_6}/)}
            else
              it { is_expected.to create_file('/etc/logrotate.d/openscap').with_content(/#{file_content_7}/)}
            end
          end

          context 'when the specified ssg_base_dir is not found' do
            let(:params){{ :ssg_base_dir => '/not/here' }}

            it { expect{is_expected.to compile.with_all_deps}.to raise_error(/No SCAP Data Streams found under/) }
          end

          context 'when the specified ssg_data_stream is not found' do
            let(:params){{ :ssg_data_stream => '/not/here.xml' }}

            it { expect{is_expected.to compile.with_all_deps}.to raise_error(/Could not find SCAP Data Stream/) }
          end

          context 'when the specified scap_profile is not found' do
            let(:params){{
              :ssg_data_stream => facts[:oscap]['profiles']['/usr/share/xml/scap/ssg/content'].keys.first + '.xml',
              :scap_profile => 'xccdf_foo_profile_meh'
            }}

            it { expect{is_expected.to compile.with_all_deps}.to raise_error(/Could not find SCAP Profile/) }
          end
        end

        context 'when forcing the installation' do
          let(:facts) { os_facts }

          let(:params) {{
            :force => true
          }}

          it_behaves_like 'a working module'
        end

        context 'when oscap is not on the system' do
          let(:facts) { os_facts }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_notify('Could not find oscap binary on the system, not setting schedule').with_loglevel('warning') }
        end

        context 'when no profiles were found on the system' do
          let(:facts) {
            oscap_fact = {
              :oscap => {
                'path' => '/bin/oscap',
                'version' => '1.2.16',
                'supported_specifications' => {
                  'XCCDF' => '1.2',
                  'OVAL' => '5.11.1'
                }
              }
            }

            os_facts.merge(oscap_fact)
          }

          it { expect{is_expected.to compile.with_all_deps}.to raise_error(/No SCAP Profiles found/) }
        end
      end
    end
  end
end
