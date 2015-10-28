# == Class: openscap
#
# This class installs SCAP content and the associated tools.
# It is mostly based on the scap-security-guide open source project
# with several customizations for SIMP.
#
# == Authors
#
# * Ralph Wright <mailto:rwright@onyxpoint.com>
#
class openscap(
  $enable_schedule = false
){

  validate_bool($enable_schedule)

  if $enable_schedule { include 'openscap::schedule' }

  package { 'openscap-utils': ensure => 'latest' }
  package { 'scap-security-guide': ensure => 'latest' }
}
