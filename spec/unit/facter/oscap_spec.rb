require 'spec_helper'

describe 'oscap' do
  before :each do
    Facter.clear
  end

  before :each do
    Facter::Core::Execution.stubs(:which).with('oscap').returns('/bin/oscap').at_least_once
    Facter::Core::Execution.stubs(:execute).with('/bin/oscap version').returns(<<-EOM
OpenSCAP command line tool (oscap) 1.2.16
Copyright 2009--2017 Red Hat Inc., Durham, North Carolina.

==== Supported specifications ====
XCCDF Version: 1.2
OVAL Version: 5.11.1
CPE Version: 2.3
CVSS Version: 2.0
CVE Version: 2.0
Asset Identification Version: 1.1
Asset Reporting Format Version: 1.1
CVRF Version: 1.1

==== Capabilities added by auto-loaded plugins ====
No plugins have been auto-loaded...

==== Paths ====
Schema files: /usr/share/openscap/schemas
Default CPE files: /usr/share/openscap/cpe
Probes: /usr/libexec/openscap
      EOM
    )
  end

  context 'with a valid environment' do
    before :each do
      Dir.stubs(:glob).with('/usr/share/xml/scap/*/content/*-ds.xml').returns([
        '/usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml',
        '/usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml'
      ]).at_least_once
    end

    it 'returns a version number and path' do
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns('')
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns('')

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['path']).to eq('/bin/oscap')
      expect(value['version']).to eq('1.2.16')
    end

    it 'returns a set of supported specifications' do
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns('')
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns('')

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['supported_specifications']).to be_a(Hash)
      expect(value['supported_specifications']['XCCDF']).to eq('1.2')
    end

    it 'returns a valid hash of all available profiles' do
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
xccdf_org.ssgproject.content_profile_CS2:Example Server Profile
        EOM
      )

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
xccdf_org.ssgproject.content_profile_pci-dss:PCI-DSS v3 Control Baseline for CentOS Linux 7
        EOM
     )

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']['xccdf_org.ssgproject.content_profile_pci-dss']).to eq('PCI-DSS v3 Control Baseline for CentOS Linux 7')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')
    end

    it 'returns a correct answer' do
      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
xccdf_org.ssgproject.content_profile_test:This has:a colon
        EOM
      )

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
        EOM
     )

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_test']).to eq('This has:a colon')
    end
  end

  context 'with malformed content' do
    it 'returns only the valid portions' do
      Dir.stubs(:glob).with('/usr/share/xml/scap/*/content/*-ds.xml').returns([
        '/usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml',
        '/usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml'
      ]).at_least_once

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
xccdf_org.ssgproject.content_profile_CS2
        EOM
      )

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
        EOM
     )

      value = Facter.fact(:oscap).value
      expect(value['profiles']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_CS2']).to be_nil
    end
  end

  context 'with invalid oscap output' do
    it 'returns only the valid portions' do
      Dir.stubs(:glob).with('/usr/share/xml/scap/*/content/*-ds.xml').returns([
        '/usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml',
        '/usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml'
      ]).at_least_once

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns(<<-EOM
xccdf_org.ssgproject.content_profile_standard:Standard System Security Profile
        EOM
      )

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns("\n")

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']).to be_a(Hash)

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos7-ds']).to be_nil

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']).to be_a(Hash)
      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_standard']).to eq('Standard System Security Profile')

      expect(value['profiles']['/usr/share/xml/scap/ssg/content']['ssg-centos6-ds']['xccdf_org.ssgproject.content_profile_CS2']).to be_nil
    end
  end

  context 'with all invalid oscap output' do
    it 'returns only the valid portions' do
      Dir.stubs(:glob).with('/usr/share/xml/scap/*/content/*-ds.xml').returns([
        '/usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml',
        '/usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml'
      ]).at_least_once

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos6-ds.xml').returns("\n")

      Facter::Core::Execution.stubs(:execute).with('/bin/oscap info --profiles /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml').returns("\n")

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_nil
    end
  end
end
