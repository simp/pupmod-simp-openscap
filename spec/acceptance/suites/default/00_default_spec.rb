require 'spec_helper_acceptance'

test_name 'openscap class'

describe 'openscap' do
  let(:manifest) do
    <<~EOS
      include 'openscap'
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      let(:skip_reason) do
        'SCAP content packages are not available from this SUTs repos ' \
        '(expected on RHEL UBI containers, which lack the full AppStream repo)'
      end

      it 'works with no errors' do
        skip skip_reason unless scap_content_available?(host)
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        skip skip_reason unless scap_content_available?(host)
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'has SCAP utils installed' do
        skip skip_reason unless scap_content_available?(host)
        expect(host.check_for_package('openscap-utils')).to be true
        expect(host.check_for_package('scap-security-guide')).to be true
      end
    end
  end
end
