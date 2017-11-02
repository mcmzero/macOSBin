#!/bin/sh

DMD=$(date -u +%y%m%d)
if [ "$(mount | grep ESP)" != "" ]; then
	tar cvzf ~/Documents/Clover/efi_$DMD.tgz -C /Volumes/ESP .
elif [ "$(mount | grep EFI)" != "" ]; then
	tar cvzf ~/Documents/Clover/efi_$DMD.tgz -C /Volumes/EFI .
fi
