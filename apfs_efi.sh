#!/bin/sh

[ -d /Volumes/ESP/EFI/CLOVER/drivers64UEFI ] && rsync -av /usr/standalone/i386/apfs.efi /Volumes/ESP/EFI/CLOVER/drivers64UEFI/apfs.efi
[ -d /Volumes/ESP/EFI/CLOVER/drivers64UEFI ] && sudo perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' /Volumes/ESP/EFI/CLOVER/drivers64UEFI/apfs.efi

[ -d /Volumes/EFI/EFI/CLOVER/drivers64UEFI ] && rsync -av /usr/standalone/i386/apfs.efi /Volumes/EFI/EFI/CLOVER/drivers64UEFI/apfs.efi
[ -d /Volumes/EFI/EFI/CLOVER/drivers64UEFI ] && sudo perl -i -pe 's|\x00\x74\x07\xb8\xff\xff|\x00\x90\x90\xb8\xff\xff|sg' /Volumes/EFI/EFI/CLOVER/drivers64UEFI/apfs.efi
