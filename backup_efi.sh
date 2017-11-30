#!/bin/sh

EFI_DEV=rdisk0s1
TARGET_PATH="$HOME/drv/Computer.localized/Clover"
EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems --exclude .svn"

DMD_UTC=$(date -u +%y%m%d-%H)
DMD=$(date +%y%m%d-%H)
if [ "$(mount | grep ESP)" != "" ]; then
	SOURCE_DIR="/Volumes/ESP"
elif [ "$(mount | grep EFI)" != "" ]; then
	SOURCE_DIR="/Volumes/EFI"
fi

#sudo tar czvf "${TARGET_PATH}"/efi_${DMD}.tgz ${EXCLUDE_TAR} -C ${SOURCE_DIR} .
#sudo dd if=/dev/$EFI_DEV bs=1m | gzip -c > "${TARGET_PATH}"/efi_${DMD}_dd.img.gz

sudo tar czvf "${TARGET_PATH}"/efi_${DMD}.tgz -C ${SOURCE_DIR} .
sudo hdiutil create -ov "${TARGET_PATH}"/efi_${DMD}.dmg -srcdevice /dev/$EFI_DEV
sudo chown changmin "${TARGET_PATH}"/*
ls -lh "${TARGET_PATH}"
