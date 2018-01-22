# Copy over our mdb ENC (external node classifier) for puppet
class mdb::enc (
) {
  file { '/usr/local/bin/mdb-enc':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file('mdb/mdb-enc.sh'),
  }
}

