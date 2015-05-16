Summary: OPENSCAP Puppet Module
Name: pupmod-openscap
Version: 4.2.0
Release: 2
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-common >= 4.2.0-0
Requires: pupmod-logrotate
Requires: pupmod-rsyslog >= 4.1.0-1
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-openscap-test

Prefix: /etc/puppet/environments/simp/modules

%description
This Puppet module provides the capability to configure openscap for your
system.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/openscap

dirs='files lib manifests'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/openscap
done

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/openscap

%files
%defattr(0640,root,puppet,0750)
%{prefix}/openscap

%post

%postun
# Post uninstall stuff

%changelog
* Fri Feb 27 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-2
- Updated to use the new 'simp' environment.
- Changed calls directly to /etc/init.d/rsyslog to '/sbin/service rsyslog' so
  that both RHEL6 and RHEL7 are properly supported.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-1
- Changed puppet-server requirement to puppet

* Sat Nov 01 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-0
- Moved set_schedule to just schedule
- Updated for the native release of OpenSCAP and the SCAP Security Guide as
  include in RHEL6.6 and higher.

* Mon Apr 07 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-0
- Updated for hiera and puppet 3 compatibility.
- Added spec tests.

* Wed Sep 11 2013 Ralph Wright <rwright@onyxpoint.com> 1.0.0-1
- Initial release
