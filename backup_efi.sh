#!/bin/sh

TARGET_DIR=/Volumes/Archives/macOS/Clover
DMD_UTC=$(date -u +%y%m%d-%H)
DMD=$(date +%y%m%d-%H)
if [ "$(mount | grep ESP)" != "" ]; then
	SOURCE_DIR="/Volumes/ESP"
elif [ "$(mount | grep EFI)" != "" ]; then
	SOURCE_DIR="/Volumes/EFI"
fi

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems --exclude .svn"

tar cvzf ${TARGET_DIR}/efi_${DMD}.tgz ${EXCLUDE_TAR} -C ${SOURCE_DIR} .
