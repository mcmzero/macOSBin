#!/bin/bash

efiPath=$(efi_mount.sh)

declare -a project=("Lilu" "Shiki" "NvidiaGraphicsFixup" "IntelGraphicsFixup")

function rebase_mcm() {
	for name in ${project[@]}; do
		cd /Users/changmin/xcode/$name
		pwd
		#git checkout mcm
		#git pull origin master
		if [ ! "$(git rebase origin/master mcm)" == "Current branch mcm is up to date." ]; then
			local build=1
		fi
	done
	[ "$build" ] && xcodebuild_mcm && zip_mcm
}

function xcodebuild_mcm() {
	for name in ${project[@]}; do
		cd /Users/changmin/xcode/$name
		xcodebuild | grep -ve export
		cp -af build/Release/*.kext ~/Downloads/kexts
		cp -af build/Release/*.kext "$efiPath"/EFI/CLOVER/kexts/Other
	done
}

function zip_mcm() {
	if cd ~/Downloads/kexts; then
		rm -f ~/Downloads/kexts.zip
		zip -r ~/Downloads/kexts.zip *.kext
		unzip -l ~/Downloads/kexts.zip
	fi
}

case $1 in
	-h)
		basename=$(basename $0)
		echo $basename rebase
		echo $basename build
		echo $basename zip
	;;
	rebase)
		rebase_mcm
	;;
	build)
		xcodebuild_mcm
	;;
	zip)
		zip_mcm
	;;
	*)
		rebase_mcm
	;;
esac
