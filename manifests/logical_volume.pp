# == Define: lvm::logical_volume
#
# @param volume_group
# @param size
# @param initial_size
# @param ensure
# @param options
# @param pass
# @param dump
# @param fs_type
# @param mkfs_options
# @param mountpath
# @param mountpath_require
# @param mounted
# @param createfs
# @param extents
# @param stripes
# @param stripesize
# @param readahead
# @param range
# @param size_is_minsize
# @param type
# @param thinpool
# @param poolmetadatasize
# @param mirror
# @param mirrorlog
# @param no_sync
# @param region_size
# @param alloc
#

#
define lvm::logical_volume (
  String $volume_group,
  Boolean $createfs                  = true,
  Boolean $mounted                   = true,
  Boolean $mountpath_require         = false,
  Enum['absent', 'present'] $ensure  = present,
  Stdlib::Absolutepath $mountpath    = "/${name}",
  String $dump                       = '0',
  String $fs_type                    = 'ext4',
  String $options                    = 'defaults',
  String $pass                       = '2',
  Variant[Boolean, String] $thinpool = false,
  Optional[String] $alloc            = undef,
  Optional[String] $extents          = undef,
  Optional[String] $initial_size     = undef,
  Optional[String] $mirror           = undef,
  Optional[String] $mirrorlog        = undef,
  Optional[String] $mkfs_options     = undef,
  Optional[String] $no_sync          = undef,
  Optional[String] $poolmetadatasize = undef,
  Optional[String] $range            = undef,
  Optional[String] $readahead        = undef,
  Optional[String] $region_size      = undef,
  Optional[String] $size             = undef,
  Optional[String] $size_is_minsize  = undef,
  Optional[String] $stripes          = undef,
  Optional[String] $stripesize       = undef,
  Optional[String] $type             = undef,
) {
  $lvm_device_path = "/dev/${volume_group}/${name}"

  if $mountpath_require and $fs_type != 'swap' {
    Mount {
      require => File[$mountpath],
    }
  }

  if $fs_type == 'swap' {
    $mount_title     = $lvm_device_path
    $fixed_mountpath = "swap_${lvm_device_path}"
    $fixed_pass      = 0
    $fixed_dump      = 0
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => present,
    }
  } else {
    $mount_title     = $mountpath
    $fixed_mountpath = $mountpath
    $fixed_pass      = $pass
    $fixed_dump      = $dump
    $mount_ensure    = $ensure ? {
      'absent' => absent,
      default  => $mounted ? {
        true      => mounted,
        false     => present,
      }
    }
  }

  if $ensure == 'present' and $createfs {
    Logical_volume[$name]
    -> Filesystem[$lvm_device_path]
    -> Mount[$mount_title]
  } elsif $ensure != 'present' and $createfs {
    Mount[$mount_title]
    -> Filesystem[$lvm_device_path]
    -> Logical_volume[$name]
  }

  logical_volume { $name:
    ensure           => $ensure,
    volume_group     => $volume_group,
    size             => $size,
    initial_size     => $initial_size,
    stripes          => $stripes,
    stripesize       => $stripesize,
    readahead        => $readahead,
    extents          => $extents,
    range            => $range,
    size_is_minsize  => $size_is_minsize,
    type             => $type,
    thinpool         => $thinpool,
    poolmetadatasize => $poolmetadatasize,
    mirror           => $mirror,
    mirrorlog        => $mirrorlog,
    no_sync          => $no_sync,
    region_size      => $region_size,
    alloc            => $alloc,
  }

  if $createfs {
    filesystem { $lvm_device_path:
      ensure  => $ensure,
      fs_type => $fs_type,
      options => $mkfs_options,
    }
  }

  if $createfs or $ensure != 'present' {
    if $fs_type != 'swap' {
      exec { "ensure mountpoint '${fixed_mountpath}' exists":
        path    => ['/bin', '/usr/bin'],
        command => "mkdir -p ${fixed_mountpath}",
        unless  => "test -d ${fixed_mountpath}",
        before  => Mount[$mount_title],
      }
    }

    mount { $mount_title:
      ensure  => $mount_ensure,
      name    => $fixed_mountpath,
      device  => $lvm_device_path,
      fstype  => $fs_type,
      options => $options,
      pass    => $fixed_pass,
      dump    => $fixed_dump,
      atboot  => true,
    }
  }
}
