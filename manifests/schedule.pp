# This class allows you to set a schedule for openscap to run a check
# on your system via cron.
#
# @param scap_profile
#   The name of the profile with the content.
#
#   * Valid profiles change based on the target system. See the results of the
#   `oscap` fact for valid targets.
#
# @param oscap_path
#   The path to the `oscap` executable
#
#   * This is set to a sane default for most systems but will pick the value
#      out of the `oscap` fact if it has been installed and is in the path.
#
# @param ssg_base_dir
#   The starting directory for all SSG content. Change this if you want to
#   install your own SSG profiles.
#
# @param ssg_data_stream
#   Type: XML file under $ssg_base_dir
#   The data stream XML file to use for your system scan. This must be a file
#   under $ssg_base_dir.
#
# @param fetch_remote_resources
#   If true, download remote content referenced by XCCDF.
#
# @param scap_tailoring_file
#   Use  given  file  for XCCDF tailoring.
#
# @param logdir
#   Specifies output location.  Default is /var/log/openscap
#
# @param logrotate
#   If true, use logrotate to rotate the output logs.
#
# @param minute
# @param hour
# @param monthday
# @param month
# @param weekday
#
# @param force
#   If set, ignore the fact that `oscap` does not appear to be installed on the
#   target system and add the schedule anyway
#
#   * This should be used if you've installed `oscap` into a non-standard
#     location that cannot be found by the fact in the default path
#
# @author https://github.com/simp/pupmod-simp-openscap/graphs/contributors
#
class openscap::schedule (
  Openscap::Profile                $scap_profile,
  Pattern[/^.+\.xml$/]             $ssg_data_stream,
  Stdlib::Absolutepath             $oscap_path             = pick(fact('oscap.path'), '/bin/oscap'),
  Stdlib::Absolutepath             $ssg_base_dir           = '/usr/share/xml/scap/ssg/content',
  Boolean                          $fetch_remote_resources = false,
  Optional[Stdlib::Absolutepath]   $scap_tailoring_file    = undef,
  Stdlib::Absolutepath             $logdir                 = '/var/log/openscap',
  Boolean                          $logrotate              = simplib::lookup('simp_options::logrotate', { 'default_value' => false}),
  Simplib::Cron::Minute            $minute                 = 30,
  Simplib::Cron::Hour              $hour                   = 1,
  Simplib::Cron::MonthDay          $monthday               = '*',
  Simplib::Cron::Month             $month                  = '*',
  Simplib::Cron::Weekday           $weekday                = 1,
  Boolean                          $force                  = false
) {
  include 'openscap'

  if $force {
    $_set_schedule = true
  }
  else {
    if $facts['oscap'] {
      $_ssg_ds_basename = basename($ssg_data_stream, '.xml')

      if !$facts['oscap']['profiles'] {
        fail('No SCAP Profiles found')
      }
      elsif !$facts['oscap']['profiles'][$ssg_base_dir] {
        fail("No SCAP Data Streams found under '${ssg_base_dir}'")
      }
      elsif !$facts['oscap']['profiles'][$ssg_base_dir][$_ssg_ds_basename] {
        fail("Could not find SCAP Data Stream '${ssg_data_stream}'")
      }
      elsif !$facts['oscap']['profiles'][$ssg_base_dir][$_ssg_ds_basename][$scap_profile] {
        fail("Could not find SCAP Profile '${scap_profile}'")
      }
      else {
        $_set_schedule = true
      }
    }
    else {
      notify { 'Could not find oscap binary on the system, not setting schedule':
        loglevel => 'warning'
      }

      $_set_schedule = false
    }
  }

  if $_set_schedule {
    file { $logdir:
      ensure => directory,
      mode   => '0600',
    }

    $host = $facts['networking']['fqdn']
    cron { 'openscap':
      command  => template('openscap/oscap_command.erb'),
      user     => 'root',
      minute   => $minute,
      hour     => $hour,
      monthday => $monthday,
      month    => $month,
      weekday  => $weekday
    }

    if $logrotate {
      include 'logrotate'

      logrotate::rule { 'openscap':
        log_files                 => [ "${logdir}/*.xml" ],
        missingok                 => true,
        rotate_period             => 'daily',
        rotate                    => 3,
        lastaction_restart_logger => true
      }
    }
  }
}
