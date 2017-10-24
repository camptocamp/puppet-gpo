GPO
===

[![Build Status](https://img.shields.io/travis/camptocamp/puppet-gpo/master.svg)](https://travis-ci.org/camptocamp/puppet-gpo)
[![Coverage Status](https://img.shields.io/coveralls/github/camptocamp/puppet-gpo.svg)](https://coveralls.io/r/camptocamp/puppet-gpo?branch=master)


## Usage

```puppet
gpo { 'windowsupdate::autoupdatecfg::allowmuupdateservice':
  ensure => present,
  value  => '1',
}
```

## Ensure absence

```puppet
gpo { 'windowsupdate::autoupdatecfg::allowmuupdateservice':
  ensure => absent,     # do not manage
}
```

```puppet
gpo { 'windowsupdate::autoupdatecfg::allowmuupdateservice':
  ensure => deleted,    # ensure registry key is deleted
}
```

## Separate namevars

```puppet
gpo { 'Allow MU Update Service':
  ensure            => present,
  admx_file         => 'WindowsUpdate',
  policy_id         => 'AutoUpdateCfg',
  setting_valuename => 'AllowMUUpdateService',
  value             => '1',
}
```

## Specify scope

```puppet
gpo { 'User::WordWheel::CustomSearch::InternetExtensionName':
  ensure => present,
  value  => '1',
}
```
