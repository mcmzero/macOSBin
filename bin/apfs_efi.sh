#!/bin/sh

efiDev=($(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2))
efiMount=$(mount|grep ${efiDev}|cut -d ' ' -f 3)
if [ "$efiMount" == "" ]; then
	diskutil mount $efiDev
	efiMount=$(mount|grep ${efiDev}|cut -d ' ' -f 3)
fi
pathDrivers64UEFI=${efiMount}/EFI/CLOVER/drivers64UEFI
if [ -d ${pathDrivers64UEFI} ]; then
	rsync -av /usr/standalone/i386/apfs.efi $pathDrivers64UEFI
	#sudo perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' ${pathDrivers64UEFI}/apfs.efi
fi
