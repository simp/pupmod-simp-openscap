# This class installs SCAP content and the associated tools.
# It is mostly based on the scap-security-guide open source project
# with several customizations for SIMP.
#
# @author Ralph Wright <mailto:rwright@onyxpoint.com>
#
class openscap(
  Boolean $enable_schedule = false
){

  if $enable_schedule { include 'openscap::schedule' }

  package { 'openscap-utils':      ensure => 'latest' }
  package { 'scap-security-guide': ensure => 'latest' }

}
