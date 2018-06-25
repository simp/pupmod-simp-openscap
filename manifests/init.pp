# This class installs SCAP content and the associated tools.
# It is mostly based on the scap-security-guide open source project
# with several customizations for SIMP.
#
# @author https://github.com/simp/pupmod-simp-openscap/graphs/contributors
#
class openscap(
  Boolean $enable_schedule = false
){

  simplib::assert_metadata($module_name)

  if $enable_schedule { include 'openscap::schedule' }

  package { 'openscap-utils':      ensure => 'latest' }
  package { 'scap-security-guide': ensure => 'latest' }

}
