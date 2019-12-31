require 'spec_helper_acceptance'

test_name 'openscap with a schedule'

describe 'openscap' do
  # For the `puppet resource` statements below
  #
  # See: https://tickets.puppetlabs.com/browse/PUP-10105
  require 'puppet'

  let(:manifest) {
    <<-EOS
      include 'openscap'
    EOS
  }

  let(:hieradata) {
    <<-EOS
---
simp_options::logrotate: true
openscap::enable_schedule: true
    EOS
  }

  hosts.each do |host|
    context "on #{host}" do
      it 'should work with no errors' do
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should have a openscap cron job' do
        cron_resource = YAML.load(on(host, 'puppet resource -y cron openscap').stdout.strip)
        expect(cron_resource['cron']['openscap']['ensure']).to eq('present')
      end

      it 'should be able to run the openscap cron job' do
        cron_resource = YAML.load(on(host, 'puppet resource -y cron openscap').stdout.strip)
        on(host, cron_resource['cron']['openscap']['command'], :acceptable_exit_codes => [0,2])
        expect( on(host, 'ls /var/log/openscap/*.html').stdout.strip ).to_not be_empty
      end
    end
  end
end
