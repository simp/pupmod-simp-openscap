# This class installs SCAP content and the associated tools.
# It is mostly based on the scap-security-guide open source project
# with several customizations for SIMP.
#
# @param enable_schedule
#   Run an OpenSCAP scan on a schedule, using `openscap::schedule`
#
# @param scap_ensure
#   Package ensure value for the `openscap-utils` package
#
# @param ssg_ensure
#   Package ensure value for the `scap-security-guide` package
#
# @author https://github.com/simp/pupmod-simp-openscap/graphs/contributors
#
class openscap (
  Boolean $enable_schedule = false,
  String $scap_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String $ssg_ensure  = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  simplib::assert_metadata($module_name)

  if $enable_schedule {
    include 'openscap::schedule'
    Class['openscap'] -> Class['openscap::schedule']
  }

  package { 'openscap-utils':
    ensure => $scap_ensure
  }
  package { 'scap-security-guide':
    ensure => $ssg_ensure
  }
}
