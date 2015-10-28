require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers
###require File.join(File.dirname(__FILE__),'helpers')

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  c.include Helpers

  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # FIXME: The EL6 tests need to install rsyslog7.  However, puppetlabs'
  # centos6 vagrant box comes with rsyslog + a big dep chain, which stops
  # rsyslog7 from getting installed.
  #
  # This workaround shanks rsyslog out of the way, however the module itself
  # should handle this upgrade somehow.
  hosts.each do |sut|
    if fact_on(sut, 'osfamily') == 'RedHat' && fact_on(sut, 'operatingsystemmajrelease') == '6'
      on(sut, 'rpm -q rsyslog && rpm -e --nodeps rsyslog', :accept_all_exit_codes => true )
      puts '*'*400 + " ^^ FIXME in the module!"
    end
  end

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    begin
      # Install modules and dependencies from spec/fixtures/modules
      copy_fixture_modules_to( hosts )
      Dir.mktmpdir do |cert_dir|
        run_fake_pki_ca_on( default, hosts, cert_dir )
        hosts.each{ |host| copy_pki_to( host, cert_dir, '/etc/pki/simp-testing' )}
      end
    rescue StandardError, ScriptError => e
      require 'pry'; binding.pry if ENV['PRY']
    end
  end

  c.after :all do
    clear_temp_hieradata
  end
end
