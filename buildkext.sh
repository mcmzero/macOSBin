#!/bin/bash

efiPath=$(efi_mount.sh)

declare -a project=("Lilu" "Shiki" "NvidiaGraphicsFixup" "IntelGraphicsFixup")

for name in ${project[@]}; do
	cd /Users/changmin/xcode/$name
	pwd
	#git checkout mcm
	#git pull origin master
	git rebase origin/master mcm
	xcodebuild | grep -ve export
	cp -af build/Release/*.kext ~/Downloads/kexts
	cp -af build/Release/*.kext "$efiPath"/EFI/CLOVER/kexts/Other
done
