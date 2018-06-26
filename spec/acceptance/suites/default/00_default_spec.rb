require 'spec_helper_acceptance'

test_name 'openscap class'

describe 'openscap' do
  let(:manifest) {
    <<-EOS
      include 'openscap'
    EOS
  }

  hosts.each do |host|
    context "on #{host}" do
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should have SCAP utils installed' do
        expect(host.check_for_package('openscap-utils')).to be true
        expect(host.check_for_package('scap-security-guide')).to be true
      end
    end
  end
end
