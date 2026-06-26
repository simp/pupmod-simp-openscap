require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

# Returns true if the SCAP content packages this module manages are actually
# obtainable from the SUT's enabled repositories.
#
# `scap-security-guide` and `openscap-utils` live in the full distribution
# AppStream repository.  The RHEL UBI container images used for the docker_rhel*
# nodesets ship only a restricted repo subset that excludes them (and there is
# no subscription available in CI), so there is genuinely nothing for this
# module to install or assert there.  EL rebuilds (Alma/Rocky/Oracle/CentOS)
# and real, entitled RHEL (e.g. under vagrant) all provide the packages.
def scap_content_available?(host)
  on(host, 'command -v dnf >/dev/null 2>&1 && dnf list --available scap-security-guide >/dev/null 2>&1 || ' \
           'yum list --available scap-security-guide >/dev/null 2>&1 || ' \
           'rpm -q scap-security-guide >/dev/null 2>&1',
     accept_all_exit_codes: true).exit_code.zero?
end

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
    # Install git, it's a dependency for inspec profiles
    # Found this when experiencing https://github.com/chef/inspec/issues/1270
    install_package(host, 'git')
  end
end

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules
    copy_fixture_modules_to(hosts)
    begin
      server = only_host_with_role(hosts, 'server')
    rescue ArgumentError => e
      server = only_host_with_role(hosts, 'default')
    end

    # Generate and install PKI certificates on each SUT
    Dir.mktmpdir do |cert_dir|
      run_fake_pki_ca_on(server, hosts, cert_dir)
      hosts.each { |sut| copy_pki_to(sut, cert_dir, '/etc/pki/simp-testing') }
    end

    # add PKI keys
    copy_keydist_to(server)
  rescue StandardError, ScriptError => e
    raise e unless ENV['PRY']
    require 'pry'
    binding.pry # rubocop:disable Lint/Debugger
  end
end
