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

  before :each do
    @data_streams = {}

    Dir.glob(File.join(fixtures, 'ssg_samples', "*-ds.xml")).each do |stream|
      @data_streams['/usr/share/xml/scap/ssg/content/' + File.basename(stream)] = IO.read(stream)
    end

    Dir.stubs(:glob).with('/usr/share/xml/scap/*/content/*-ds.xml').returns(@data_streams.keys).at_least_once
  end

  context 'with a valid environment' do
    it 'returns a version number and path' do
      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['path']).to eq('/bin/oscap')
      expect(value['version']).to eq('1.2.16')
    end

    it 'returns a set of supported specifications' do
      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['supported_specifications']).to be_a(Hash)
      expect(value['supported_specifications']['XCCDF']).to eq('1.2')
    end

    it 'returns a valid hash of all available profiles' do
      @data_streams.each_pair do |stream, content|
        File.stubs(:read).with(stream).returns(content)
      end

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_a(Hash)

      ds_level = value['profiles']['/usr/share/xml/scap/ssg/content']
      expect(ds_level).to be_a(Hash)

      ds_level.each_pair do |ds, profile|
        expect(profile).to be_a(Hash)

        profile.each_pair do |k, v|
          expect(k).to match(/^xccdf_org\.ssgproject\./)
          if v
            expect(v).to be_a(String)
          end
        end
      end
    end
  end

  context 'with random invalid oscap output' do
    it 'returns only the valid portions' do
      i = 0
      @data_streams.each_pair do |stream, content|
        if ( (i % 2) == 1 )
          File.stubs(:read).with(stream).returns("Look, some random garbage with Profile and title!")
        else
          File.stubs(:read).with(stream).returns(content)
        end

        i += 1
      end

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_a(Hash)

      ds_level = value['profiles']['/usr/share/xml/scap/ssg/content']
      expect(ds_level).to be_a(Hash)

      ds_level.each_pair do |ds, profile|
        expect(profile).to be_a(Hash)

        profile.each_pair do |k, v|
          expect(k).to match(/^xccdf_org\.ssgproject\./)
          if v
            expect(v).to be_a(String)
          end
        end
      end
    end
  end

  context 'with all invalid oscap output' do
    it 'returns only the valid portions' do
      @data_streams.each_pair do |stream, content|
        File.stubs(:read).with(stream).returns("\n")
      end

      value = Facter.fact(:oscap).value

      expect(value).to be_a(Hash)
      expect(value['profiles']).to be_nil
    end
  end
end
