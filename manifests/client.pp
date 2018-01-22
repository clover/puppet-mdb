class mdb::client (
  String $etcd_server,
) {

  package { 'mdb':
    ensure => 'installed',
  }

  file {'/etc/mdb':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {'/etc/mdb/config.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "server: ${etcd_server}\n",
    require => [ File['/etc/mdb'], ],
  }
}

