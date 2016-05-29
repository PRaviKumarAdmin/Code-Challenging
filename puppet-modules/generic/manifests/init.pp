
class generic {

  #  Adding group minimum required.
  group { 'techops_dba':
    ensure => 'present',
    gid    => '4000',
  }

  file { '/etc/security/access.conf':
    ensure => 'present',
    group  => 'techops_dba',
    mode   => '0644',
  }

  file { '/etc/sudoers':
    ensure  => 'present',
    group   => 'techops_dba',
    mode    => '0600',
    content => '//Source-file',
  }
}

  
