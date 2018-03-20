#!/bin/bash

mount_efi() {
diskutil mount $(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2)
}

EFI_DEV=($(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2))
EFI_MOUNT=$(mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
if [ "$EFI_MOUNT" == "" ]; then
	diskutil mount $EFI_DEV
	EFI_MOUNT=$(mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
fi
echo $EFI_MOUNT
open $EFI_MOUNT
