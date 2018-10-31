[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/openscap.svg)](https://forge.puppetlabs.com/simp/openscap)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/openscap.svg)](https://forge.puppetlabs.com/simp/openscap)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-openscap.svg)](https://travis-ci.org/simp/pupmod-simp-openscap)

#### Table of Contents

1. [Overview](#this-is-a-simp-module)
2. [Module Description - A Puppet module for managing openscap](#module-description)
3. [Setup - The basics of getting started with pupmod-simp-openscap](#setup)
    * [What pupmod-simp-openscap affects](#what-simp-openscap-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with openscap](#beginning-with-openscap)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## This is a SIMP module
This module is a component of the
[System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our
[JIRA](https://simp-project.atlassian.net/).

This module is optimally designed for use within a larger SIMP ecosystem, but it
can be used independently:
* When included within the SIMP ecosystem, security compliance settings will be
managed from the Puppet server.
* In the future, all SIMP-managed security subsystems will be disabled by
default and must be explicitly opted into by administrators.  Please review
*simp/simp_options* for details.

## Module Description

This module sets up [openscap](https://www.open-scap.org/) and allows you to
schedule and log openscap runs.

## Setup

### What simp openscap affects

`simp/openscap` will manage:

* openscap-utils and scap-security-guide packages

`simp/openscap::schedule` will manage:

* A cron job for openscap runs
* A logging directory for openscap (Default: /var/log/openscap)

### Setup Requirements

The module can support logrotate if *simp/logrotate* is used. Otherwise, no
additional setup is required.

### Beginning with openscap

You can install openscap by:

```puppet
include 'openscap'
```

## Usage

### I want to install openscap with default logging

The following will run a cron job on Monday at 1:30 AM and log to
/var/log/openscap:

```puppet
class { 'openscap':
  enable_schedule => true,
}
```

OR

```puppet
include 'openscap::schedule'
```

### I have a particular SCAP profile I want to use

```puppet
class { 'openscap::schedule':
  scap_profile => 'xccdf_org.ssgproject.content_profile_stig-rhel7-server-upstream',
}
```

### I want to log daily at a set time

```puppet
class { 'openscap::schedule':
  minute  => 00,
  hour    => 22,
  weekday => '*',
}
```

### I want to log on the first and fifteenth day of the month

```puppet
class { 'openscap::schedule':
  monthday => '1,15',
}
```

### I want to log to a different directory

```puppet
class { 'openscap::schedule':
  logdir => '/opt/scaplogs',
}
```

## Reference

Please see the [REFERENCE.md](REFERENCE.md).

## Limitations

This module is only designed to work in RHEL or CentOS 6 and 7. Any other
operating systems have not been tested and results cannot be guaranteed.

# Development

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).
