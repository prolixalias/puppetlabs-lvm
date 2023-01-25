# == Define: lvm::physical_volume
#
# @param force
# @param ensure
# @param unless_vg
#

#
define lvm::physical_volume (
  Boolean $force               = false,
  String $ensure               = present,
  Optional[String] $unless_vg  = undef,
) {
  if ($name == undef) {
    fail("lvm::physical_volume \$name can't be undefined")
  }

  physical_volume { $name:
    ensure    => $ensure,
    force     => $force,
    unless_vg => $unless_vg,
  }
}
