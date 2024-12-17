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
      retval['version'] = Regexp.last_match(1).strip
    end

    # Now get the supported versions of the various specs
    if version_info =~ %r{=+ Supported specifications =+(.*?)(^\s*$|=+)}m
      retval['supported_specifications'] = Regexp.last_match(1).lines.map do |l|
        id, ver = l.split(%r{\s*Version:\s*})

        if id && ver
          [id.strip, ver.strip]
        else
          nil
        end
      end

      retval['supported_specifications'] = Hash[retval['supported_specifications'].compact]
    end

    # The XML can have anything in there
    Encoding.default_external = Encoding::UTF_8

    # Get the available profiles on the system
    Dir.glob('/usr/share/xml/scap/*/content/*-ds.xml').each do |data_stream|
      path = File.dirname(data_stream)
      ds = File.basename(data_stream, '.xml')

      # Full XML processing takes too long so we'll do it slightly more efficiently
      entries = File.read(data_stream).scan(%r{(?:<(?:.+:)?Profile\s+id="(.+)">|<(?:.+:)?title\s+.+>(.*?)</title>)})

      if entries && !entries.empty?
        entries = entries.flatten.compact

        entries.each_with_index do |x, i|
          next unless x.start_with?('xccdf_org.ssg')

          retval['profiles'] ||= {}
          retval['profiles'][path] ||= {}
          retval['profiles'][path][ds] ||= {}

          retval['profiles'][path][ds][x] = entries[i + 1]
        end
      end
    rescue => e
      Facter.log_exception(e, "oscap: Error processing data stream '#{data_stream}'")
    end

    retval
  end
end
