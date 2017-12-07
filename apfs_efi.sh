#!/bin/sh

[ -d /Volumes/ESP/EFI/CLOVER/drivers64UEFI ] && rsync -auv /usr/standalone/i386/apfs.efi /Volumes/ESP/EFI/CLOVER/drivers64UEFI/apfs.efi
[ -d /Volumes/EFI/EFI/CLOVER/drivers64UEFI ] && rsync -auv /usr/standalone/i386/apfs.efi /Volumes/EFI/EFI/CLOVER/drivers64UEFI/apfs.efi
