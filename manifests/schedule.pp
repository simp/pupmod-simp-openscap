# == Class: openscap::schedule
#
# This class allows you to set a schedule for openscap to run a check
# on your system via cron.
#
# == Parameters
#
# [*scap_profile*]
#   Type: String
#   Default: "xccdf_org.ssgproject.content_profile_stig-rhel${::operatingsystemmajrelease}-server-upstream"
#
#   Should be the name of the profile with the conent.
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
# [*scap_tailoring_file*]
#   Type: Absolute Path
#   Default: ''
#
# [*ssg_base_dir*]
#   Type: Absolute Path
#   Default: "/usr/share/xml/scap/ssg/rhel${::operatingsystemmajrelease}"
#
#   The starting directory for all SSG content. Change this if you want to
#   install your own SSG profiles.
#
# [*ssg_data_stream*]
#   Type: XML file under $ssg_base_dir
#   Default: "ssg-rhel${::operatingsystemmajrelease}-ds.xml"
#
#   The data stream XML file to use for your system scan. This must be a file
#   under $ssg_base_dir.
#
# [*fetch_remote_resource*]
#   Type: Boolean
#   Default: false
#
#   If true, download remote content referenced by XCCDF.
#
# [*logdir*]
#   Type: Absolute Path
#   Default: '/var/log/openscap'
#
#   Specifies output location.  Default is /var/log/openscap
#
# [*rotate_logs*]
#   Type: Boolean
#   Default: true
#
#   If true, use logrotate to rotate the output logs.
#
# [*minute*]
# [*hour*]
# [*monthday*]
# [*month*]
# [*weekday*]
#
# == Authors
#  * Ralph Wright <rwright@onyxpoint.com>
#  * Trevor Vaughan <tvaughan@onyxpoint.com>
#  * Kendall Moore <kmoore@keywcorp.com>
#
class openscap::schedule (
  $scap_profile = "xccdf_org.ssgproject.content_profile_stig-rhel${::operatingsystemmajrelease}-server-upstream",
  $scap_tailoring_file = false,
  $ssg_base_dir = "/usr/share/xml/scap/ssg/rhel${::operatingsystemmajrelease}",
  $ssg_data_stream = "ssg-rhel${::operatingsystemmajrelease}-ds.xml",
  $fetch_remote_resources = false,
  $logdir = '/var/log/openscap',
  $rotate_logs = true,
  $minute = '30',
  $hour = '1',
  $monthday = '*',
  $month = '*',
  $weekday = '1'
) {
  include 'openscap'

  file { $logdir:
    ensure  => directory,
    mode    => '0600',
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

  if $rotate_logs {
    include 'logrotate'

    logrotate::add { 'openscap':
      log_files     => [ "${logdir}/*.xml" ],
      missingok     => true,
      rotate_period => 'daily',
      rotate        => '3',
      lastaction    => '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
    }
  }

  $valid_profiles = [
    'xccdf_org.ssgproject.content_profile_test',
    'xccdf_org.ssgproject.content_profile_CS2',
    'xccdf_org.ssgproject.content_profile_common',
    'xccdf_org.ssgproject.content_profile_server',
    'xccdf_org.ssgproject.content_profile_stig-rhel6-server-upstream',
    'xccdf_org.ssgproject.content_profile_usgcb-rhel6-server',
    'xccdf_org.ssgproject.content_profile_rht-ccp',
    'xccdf_org.ssgproject.content_profile_CSCF-RHEL6-MLS',
    'xccdf_org.ssgproject.content_profile_C2S',
    'xccdf_org.ssgproject.content_profile_test',
    'xccdf_org.ssgproject.content_profile_rht-ccp',
    'xccdf_org.ssgproject.content_profile_common',
    'xccdf_org.ssgproject.content_profile_stig-rhel7-server-upstream'
  ]

  validate_array_member($scap_profile,$valid_profiles)
  if $scap_tailoring_file { validate_absolute_path($scap_tailoring_file) }
  validate_absolute_path($ssg_base_dir)
  validate_re($ssg_data_stream,'^.+\.xml$')
  validate_bool($fetch_remote_resources)
  validate_absolute_path($logdir)
  validate_bool($rotate_logs)
  unless $minute == '*' { validate_between($minute,0,59) }
  unless $hour == '*' { validate_between($hour,0,23) }
  unless $monthday == '*' { validate_between($monthday,1,31) }
  unless $month == '*' { validate_between($month,1,12) }
  unless $weekday == '*' { validate_between($weekday,0,7) }
}
