# puppet-role_netbox

Puppet role definition for deployment of netbox using docker and traefik

## Parameters

TBD

## Classes

- role_netbox::init

## Dependencies

gareth/docker

Puppet code:

```
class { role_netbox: }
```

## Result

Netbox deployment using docker-compose which should result in a running
netbox installation.

## Limitations

This module has been built on and tested against Puppet 4 and higher.

The module has been tested on:

- Ubuntu 16.04LTS

Dependencies releases tested:

- garethr/docker 5.3.0

## Authors

David Heijkamp <david.heijkamp@naturalis.nl>
