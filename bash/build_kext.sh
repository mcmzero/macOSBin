#!/bin/bash

efiPath=$(efi_mount.sh)
targetPath="$HOME/Downloads/zips"

declare -a project=("Lilu" "Shiki" "NvidiaGraphicsFixup" "IntelGraphicsFixup")

function log_one_mcm() {
	for name in ${project[@]}; do
		if cd /Users/changmin/xcode/$name; then
			pwd
			git log -1
		fi
	done
}

function rebase_mcm() {
	local build=1
	for name in ${project[@]}; do
		if cd /Users/changmin/xcode/$name; then
			pwd
			#git checkout mcm && git pull origin master
			[ "$(git rebase origin/master mcm)" == "Current branch mcm is up to date." ] || build=0
		fi
	done
	if [[ $build == 1 ]]; then
		log_one_mcm
	fi
	return $build
}

function xcodebuild_mcm() {
	for name in ${project[@]}; do
		if cd /Users/changmin/xcode/$name; then
			xcodebuild | grep -ve export
		fi
	done
}

function zip_mcm() {
	for name in ${project[@]}; do
		if cd /Users/changmin/xcode/$name; then
			rsync -v -auz --delete build/Release/*.kext $efiPath/EFI/CLOVER/kexts/Other
			[ -d $targetPath/kexts/Other ] || mkdir -p $targetPath/kexts/Other
			rsync -v -auz --delete build/Release/*.kext $targetPath/kexts/Other
		fi
	done

	if cd $targetPath/kexts; then
		rm -f $targetPath/kexts.zip
		zip -r $targetPath/kexts.zip Other && rm -rf $targetPath/kexts
		unzip -l $targetPath/kexts.zip
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
	force|-f)
		rebase_mcm; xcodebuild_mcm && zip_mcm
	;;
	*)
		rebase_mcm && xcodebuild_mcm && zip_mcm && log_one_mcm
	;;
esac
