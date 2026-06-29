require 'spec_helper_acceptance'

test_name 'openscap with a schedule'

describe 'openscap' do
  # For the `puppet resource` statements below
  #
  # See: https://tickets.puppetlabs.com/browse/PUP-10105
  require 'puppet'

  let(:manifest) do
    <<~EOS
      include 'openscap'
    EOS
  end

  let(:hieradata) do
    <<~EOS
      ---
      simp_options::logrotate: true
      openscap::enable_schedule: true
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      let(:skip_reason) do
        'SCAP content packages are not available from this SUTs repos ' \
        '(expected on RHEL UBI containers, which lack the full AppStream repo)'
      end

      it 'has cron installed' do
        skip skip_reason unless scap_content_available?(host)
        # Minimal containers do not ship cron; the `cron` resource provider
        # (and the scheduled scan) require the crontab tooling to be present.
        host.install_package('cronie')
      end

      it 'works with no errors' do
        skip skip_reason unless scap_content_available?(host)
        set_hieradata_on(host, hieradata)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        skip skip_reason unless scap_content_available?(host)
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has a openscap cron job' do
        skip skip_reason unless scap_content_available?(host)
        cron_resource = YAML.safe_load(on(host, 'puppet resource -y cron openscap').stdout.strip)
        expect(cron_resource['cron']['openscap']['ensure']).to eq('present')
      end

      it 'is able to run the openscap cron job' do
        skip skip_reason unless scap_content_available?(host)
        cron_resource = YAML.safe_load(on(host, 'puppet resource -y cron openscap').stdout.strip)
        on(host, cron_resource['cron']['openscap']['command'], acceptable_exit_codes: [0, 2])
        expect(on(host, 'ls /var/log/openscap/*.html').stdout.strip).not_to be_empty
      end
    end
  end
end
