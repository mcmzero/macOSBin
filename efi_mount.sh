#!/bin/bash
export PATH=$PATH:/usr/bin:/bin:/usr/sbin:/sbin:~/bin

mount_efi() {
	/usr/sbin/diskutil mount $(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2)
}

EFI_DEV=($(/usr/sbin/diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2))
EFI_MOUNT=$(/sbin/mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
if [ -z "$EFI_MOUNT" ]; then
	/usr/sbin/diskutil mount $EFI_DEV &> /dev/null
	EFI_MOUNT=$(/sbin/mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
fi
echo $EFI_MOUNT
#open $EFI_MOUNT
