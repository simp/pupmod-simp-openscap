require 'spec_helper_acceptance'

test_name 'openscap class'

describe 'openscap' do
  let(:manifest) do
    <<~EOS
      include 'openscap'
    EOS
  end

  hosts.each do |host|
    # Exercise noop from a clean (uninstalled) state: on a fresh node the Sicura
    # console previews the module with `puppet apply --noop`, which must not error
    # even though nothing openscap manages exists yet. Real idempotence is covered
    # by the applies below. A post-convergence noop check is deliberately omitted:
    # `puppet apply --noop --detailed-exitcodes` always exits 0, so it could never
    # fail and would test nothing.
    context 'in noop mode from a clean state' do
      # Setup, not an assertion: as before(:context) a failure errors this context
      # rather than aborting the whole suite under .rspec's --fail-fast. `puppet
      # resource` exits 0 whether it removes the package or finds it already absent
      # (no --detailed-exitcodes), so no acceptable_exit_codes override is needed.
      before(:context) do
        on(host, 'puppet resource package openscap-utils ensure=absent')
        on(host, 'puppet resource package scap-security-guide ensure=absent')
      end

      it 'applies without errors in noop mode' do
        apply_manifest_on(host, manifest, catch_failures: true, noop: true)
      end
    end

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
