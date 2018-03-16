#!/bin/bash

EFI_DEV=($(diskutil list|grep EFI|head -n 1|cut -d 'B' -f 2))
EFI_MOUNT=$(mount|grep ${EFI_DEV}|cut -d ' ' -f 3)
[ "$EFI_MOUNT" == "" ] && diskutil mount $EFI_DEV
[ "$EFI_MOUNT" != "" ] && echo $EFI_MOUNT
if [ "$EFI_MOUNT" == "" ]; then
	echo "Cannot find EFI directory"
	exit 1
fi

SOURCE_DIR=$EFI_MOUNT
TARGET_PATH="$HOME/drv/Computer.localized/Clover"
EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems --exclude .svn"
DMD_UTC=$(date -u +%y%m%d-%H)
DMD=$(date +%y%m%d-%H)

#sudo tar czvf "${TARGET_PATH}"/efi_${DMD}.tgz ${EXCLUDE_TAR} -C ${SOURCE_DIR} .
#sudo dd if=/dev/r${EFI_DEV} bs=1m | gzip -c > "${TARGET_PATH}"/efi_${DMD}_dd.img.gz

sudo tar czvf "${TARGET_PATH}"/efi_${DMD}.tgz -C ${SOURCE_DIR} .
sudo hdiutil create -ov "${TARGET_PATH}"/efi_${DMD}.dmg -srcdevice /dev/r$EFI_DEV
sudo chown changmin "${TARGET_PATH}"/*

rsync -auzv --delete ${TARGET_PATH}/ $HOME/Seafile/EFI

ls -lh "${TARGET_PATH}"
