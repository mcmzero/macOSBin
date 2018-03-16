#!/bin/bash

mount_efi() {
diskutil mount $(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2)
}

EFI_DEV=($(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2))
EFI_MOUNT=$(mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
[ "$EFI_MOUNT" == "" ] && diskutil mount $EFI_DEV
[ "$EFI_MOUNT" != "" ] && echo $EFI_MOUNT
