# == Class: lvm
#
# @summary Provides Logical Resource Management (LVM) features for Puppet
#
# @param package_ensure
# @param manage_pkg
# @param volume_groups
#

#
class lvm (
  Boolean $manage_pkg                                              = false,
  Enum['installed', 'present', 'latest', 'absent'] $package_ensure = 'installed',
  Hash $volume_groups                                              = {},
) {
  if $manage_pkg {
    package { 'lvm2':
      ensure   => $package_ensure,
    }
  }

  create_resources('lvm::volume_group', $volume_groups)
}
