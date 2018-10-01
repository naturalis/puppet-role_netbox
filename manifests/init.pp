# == Class: role_netbox
#
# === Authors
#
# David Heijkamp <david.heijkamp@naturalis.nl>
#
# === Copyright
#
# Apache2 license 2018.
#
class role_netbox (
  $compose_version        = '1.17.0',
  $repo_source            = 'https://github.com/ninech/netbox-docker.git',
  $repo_ensure            = 'present',
  $repo_revision          = '0.5.0',
  $repo_dir               = '/opt/netbox',
  $downstream_repo_source = 'https://github.com/naturalis/docker-netbox-traefik',
  $downstream_repo_ensure = 'latest',
  $downsteam_repo_dir     = '/opt/netbox_downstream',
  $lets_encrypt_mail       = 'mail@example.com',
  $traefik_toml_file       = '/opt/traefik/traefik.toml',
  $traefik_acme_json       = '/opt/traefik/acme.json'

){

  include 'docker'
  include 'stdlib'
  $timestamp = strftime('%Y-%m-%d')

  Exec {
    path => '/usr/local/bin/',
    cwd  => "${role_netbox::repo_dir}",
  }

  file { ['/data','/opt/traefik'] :
    ensure => directory,
  }

  file { $traefik_toml_file :
    ensure  => file,
    content => template('role_netbox/traefik.toml.erb'),
    require => File['/opt/traefik'],
    notify  => Exec['Restart containers on change'],
  }

  file { $traefik_acme_json :
    ensure  => present,
    mode    => '0600',
    require => File['/opt/traefik'],
    notify  => Exec['Restart containers on change'],
  }

  file { "${role_netbox::repo_dir}/env":
    ensure => directory,
  }

  file { "${role_netbox::repo_dir}/env/netbox.env":
    ensure  => file,
    content => template('role_netbox/netbox.env.erb'),
    require => Vcsrepo[$role_netbox::repo_dir],
    notify  => Exec['Restart containers on change'],
  }

  file { "${role_netbox::repo_dir}/env/postgres.env":
    ensure  => file,
    content => template('role_netbox/postgres.env.erb'),
    require => Vcsrepo[$role_netbox::repo_dir],
    notify  => Exec['Restart containers on change'],
  }

  file { "${role_netbox::repo_dir}/env/redis.env":
    ensure  => file,
    content => template('role_netbox/redis.env.erb'),
    require => Vcsrepo[$role_netbox::repo_dir],
    notify  => Exec['Restart containers on change'],
  }

  file { "${role_netbox::repo_dir}/env/traefik.env":
    ensure  => file,
    content => template('role_netbox/traefik.env.erb'),
    require => Vcsrepo[$role_netbox::repo_dir],
    notify  => Exec['Restart containers on change'],
  }

  class {'docker::compose':
    ensure  => present,
    version => $role_netbox::compose_version
  }

  package { 'git':
    ensure => installed,
  }

  vcsrepo { $role_netbox::repo_dir:
    ensure   => $role_netbox::repo_ensure,
    source   => $role_netbox::repo_source,
    provider => 'git',
    revision => $role_netbox::repo_revision,
    require  => Package['git']
  }

  docker_network { 'web':
    ensure => present,
  }

  docker_compose { "${role_netbox::downstream_repo_dir}/docker-compose.yml":
    ensure  => present,
    options => "-f ${role_netbox::downstream_repo_dir}/docker-compose.yml --project-directory ${role_salep::repo_dir}",
    require => [
      Vcsrepo[$role_netbox::repo_dir],
      File[$traefik_acme_json],
      File["${role_netbox::repo_dir}/env/netbox.env"],
      File["${role_netbox::repo_dir}/env/postgres.env"],
      File["${role_netbox::repo_dir}/env/redis.env"],
      File["${role_netbox::repo_dir}/env/traefik.env"],
      File[$traefik_toml_file],
      Docker_network['web']
    ]
  }

  exec { 'Pull containers' :
    command  => 'docker-compose pull',
    schedule => 'everyday',
  }

  exec { 'Up the containers to resolve updates' :
    command  => 'docker-compose up -d',
    schedule => 'everyday',
    require  => Exec['Pull containers']
  }

exec {'Restart containers on change':
  refreshonly => true,
  command     => 'docker-compose up -d',
  require     => Docker_compose["${role_netbox::repo_dir}/docker-compose.yml"],
}

# deze gaat per dag 1 keer checken
# je kan ook een range aan geven, bv tussen 7 en 9 's ochtends
schedule { 'everyday':
  period => daily,
  repeat => 1,
  range  => '5-7',
}
