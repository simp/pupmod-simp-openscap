# Returns available SCAP profiles as a Hash in the following format
#
# 'path'                     => '<path to oscap command>',
# 'version'                  => '<oscap version number>',
# 'supported_specifications' => {
#   '<specification name>' => '<specification version>',
#   '<specification name>' => '<specification version>'
# },
# 'profiles'                 => {
#   '<source directory>' => {
#     '<data stream>' => {
#       '<profile id>' => '<profile description>',
#       '<profile id>' => '<profile description>'
#     }
#   }
# }
#
# @example SSG Output
#
# 'path'                     => '/bin/oscap',
# 'version'                  => '1.2.16',
# 'supported_specifications' => {
#   'XCCDF' => '1.2',
#   'OVAL'  => '5.11.1'
# },
# 'profiles'                 => {
#   '/usr/share/xml/scap/ssg/content' => {
#     'ssg-centos7-ds' => {
#       'xccdf_org.ssgproject.content_profile_standard' => 'Standard System Security Profile'
#     }
#   }
# }
#
Facter.add('oscap') do
  confine { Facter::Core::Execution.which('oscap') }
  confine { !Dir.glob('/usr/share/xml/scap/*/content/*-ds.xml').empty? }

  setcode do
    oscap = Facter::Core::Execution.which('oscap')

    retval = { 'path' => oscap }

    # This is a big dump of information that we'll be pulling a few things from
    version_info = Facter::Core::Execution.execute("#{oscap} version")

    # Get the version of oscap on the system
    if version_info =~ %r{^\s*OpenSCAP command line tool.*(\d+\.\d+\.\d+)$}
      retval['version'] = $1.strip
    end

    # Now get the supported versions of the various specs
    if version_info =~ %r{=+ Supported specifications =+(.*?)(^\s*$|=+)}m
      retval['supported_specifications'] = $1.lines.map do |l|
        id, ver = l.split(/\s*Version:\s*/)

        if id && ver
          [id.strip, ver.strip]
        else
          nil
        end
      end

      retval['supported_specifications'] = Hash[retval['supported_specifications'].compact]
    end

    # Get the available profiles on the system
    Dir.glob('/usr/share/xml/scap/*/content/*-ds.xml').each do |data_stream|
      path = File.dirname(data_stream)
      ds = File.basename(data_stream, '.xml')

      oscap_info = Facter::Core::Execution.execute("#{oscap} info --profiles #{data_stream}").strip

      next unless (oscap_info && !oscap_info.empty?)

      retval['profiles'] ||= {}
      retval['profiles'][path] ||= {}
      retval['profiles'][path][ds] ||= {}

      oscap_info.lines.each do |line|
        profile_id, *profile_desc = line.split(':')

        next unless (profile_id && profile_desc)
        profile_id.strip!

        # In case some description has a colon in it
        profile_desc = Array(profile_desc).join(':')
        profile_desc.strip!

        next if profile_desc.empty?
        next if profile_id.empty?

        retval['profiles'][path][ds][profile_id.strip] = profile_desc.strip
      end
    end

    retval
  end
end
