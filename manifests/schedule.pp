# This class allows you to set a schedule for openscap to run a check
# on your system via cron.
#
# @param scap_profile
#   The name of the profile with the content.
#    Valid RHEL/CentOS 6 Choices:
#      * xccdf_org.ssgproject.content_profile_test
#      * xccdf_org.ssgproject.content_profile_CS2
#      * xccdf_org.ssgproject.content_profile_common
#      * xccdf_org.ssgproject.content_profile_server
#      * xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream
#      * xccdf_org.ssgproject.content_profile_usgcb-rhel6-server
#      * xccdf_org.ssgproject.content_profile_rht-ccp
#      * xccdf_org.ssgproject.content_profile_CSCF-RHEL6-MLS
#      * xccdf_org.ssgproject.content_profile_C2S
#
#    Valid RHEL/CentOS 7 Choice:
#      * xccdf_org.ssgproject.content_profile_test
#      * xccdf_org.ssgproject.content_profile_rht-ccp
#      * xccdf_org.ssgproject.content_profile_common
#      * xccdf_org.ssgproject.content_profile_stig-rhel7-server-upstream
#
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
# @param fetch_remote_resource
#   If true, download remote content referenced by XCCDF.
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
# @author Ralph Wright <rwright@onyxpoint.com>
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
# @author Kendall Moore <kmoore@keywcorp.com>
#
class openscap::schedule (
  Openscap::Profile                $scap_profile,
  Pattern[/^.+\.xml$/]             $ssg_data_stream,
  Stdlib::Absolutepath             $ssg_base_dir           = '/usr/share/xml/scap/ssg/content',
  Boolean                          $fetch_remote_resources = false,
  Stdlib::Absolutepath             $logdir                 = '/var/log/openscap',
  Boolean                          $logrotate              = simplib::lookup('simp_options::logrotate', { 'default_value' => false}),
  Variant[Enum['*'],Integer[0,59]] $minute                 = 30,
  Variant[Enum['*'],Integer[0,23]] $hour                   = 1,
  Variant[Enum['*'],Integer[1,31]] $monthday               = '*',
  Variant[Enum['*'],Integer[1,12]] $month                  = '*',
  Variant[Enum['*'],Integer[0,7]]  $weekday                = 1
) {
  include '::openscap'

  file { $logdir:
    ensure => directory,
    mode   => '0600',
  }

  cron { 'openscap':
    command  => template('openscap/oscap_command.erb'),
    user     => 'root',
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday,
    require  => [
      Package['scap-security-guide'],
      Package['openscap-utils']
    ]
  }

  if $logrotate {
    include '::logrotate'

    logrotate::rule { 'openscap':
      log_files                 => [ "${logdir}/*.xml" ],
      missingok                 => true,
      rotate_period             => 'daily',
      rotate                    => 3,
      lastaction_restart_logger => true
    }
  }

}
