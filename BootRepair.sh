#!/bin/sh

sudo chown root:admin /
sudo kextcache -prelinked-kernel
sudo kextcache -system-caches
diskutil repairPermissions /
