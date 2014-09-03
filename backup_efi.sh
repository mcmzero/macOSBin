#!/usr/bin/osascript

do shell script "cd /Volumes/EFI;zip -r '/Volumes/Drive/Google Drive/OS X/efi.zip' *"
do shell script "umount -f /Volumes/EFI;dd if=/dev/disk0s1 of='/Volumes/Drive/Google Drive/OS X/efi.img'" password "ibsofaids" with administrator privileges
do shell script "mkdir -p /Volumes/EFI && mount -t msdos /dev/disk0s1 /Volumes/EFI" password "ibsofaids" with administrator privileges
