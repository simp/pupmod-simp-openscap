require 'spec_helper'

shared_examples 'a working module' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('openscap::schedule') }
  it { is_expected.to create_class('openscap') }

  it { is_expected.to create_file('/var/log/openscap') }
end

describe 'openscap::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}", skip: ((os =~ %r{rocky}i) ? 'Rocky Linux does not currently have any officially supported ssg streams' : nil) do
      context 'with a valid environment' do
        let(:facts) do
          oscap_fact = {
            oscap: {
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
        end

        let(:params) do
          {
            scap_profile: 'xccdf_org.ssgproject.content_profile_standard',
         ssg_data_stream: "ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds.xml"
          }
        end

        it_behaves_like 'a working module'
        command = "/bin/oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_standard --results /var/log/openscap/foo.example.com-ssg-results-xccdf_org.ssgproject.content_profile_standard-`date +%Y%m%d%H%M%S`.xml --report /var/log/openscap/foo.example.com-ssg-results-xccdf_org.ssgproject.content_profile_standard-`date +%Y%m%d%H%M%S`.html /usr/share/xml/scap/ssg/content/ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds.xml\n"
        it {
          is_expected.to create_cron('openscap') \
            .with_command(command)
        }

        context 'with logrotate => true' do
          let(:params) do
            {
              scap_profile: 'xccdf_org.ssgproject.content_profile_standard',
           ssg_data_stream: "ssg-#{os_facts[:operatingsystem].downcase}#{os_facts[:operatingsystemmajrelease]}-ds.xml",
           logrotate: true
            }
          end

          it_behaves_like 'a working module'
          it { is_expected.to create_class('logrotate') }
          it {
            is_expected.to create_logrotate__rule('openscap').with(
            { log_files: [ '/var/log/openscap/*.xml' ] },
          )
          }
        end

        context 'when the specified ssg_base_dir is not found' do
          let(:params) { { ssg_base_dir: '/not/here' } }

          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{No SCAP Data Streams found under}) }
        end

        context 'when the specified ssg_data_stream is not found' do
          let(:params) { { ssg_data_stream: '/not/here.xml' } }

          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{Could not find SCAP Data Stream}) }
        end

        context 'when the specified scap_profile is not found' do
          let(:params) do
            {
              ssg_data_stream: facts[:oscap]['profiles']['/usr/share/xml/scap/ssg/content'].keys.first + '.xml',
           scap_profile: 'xccdf_foo_profile_meh'
            }
          end

          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{Could not find SCAP Profile}) }
        end
      end

      context 'when forcing the installation' do
        let(:facts) { os_facts }

        let(:params) do
          {
            force: true
          }
        end

        it_behaves_like 'a working module'
      end

      context 'when oscap is not on the system' do
        let(:facts) { os_facts }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_notify('Could not find oscap binary on the system, not setting schedule').with_loglevel('warning') }
      end

      context 'when no profiles were found on the system' do
        let(:facts) do
          oscap_fact = {
            oscap: {
              'path' => '/bin/oscap',
              'version' => '1.2.16',
              'supported_specifications' => {
                'XCCDF' => '1.2',
                'OVAL' => '5.11.1'
              }
            }
          }

          os_facts.merge(oscap_fact)
        end

        it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{No SCAP Profiles found}) }
      end
    end
  end
end
