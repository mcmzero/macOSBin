#!/bin/bash

sourceVolume=/Volumes/macOS
targetVolume=/Volumes/Backup.localized

function backup() {
	echo rsync backup
	if [ ! -d $targetVolume/Sync.localized ]; then
		mkdir -p $targetVolume/Sync.localized
		cp -a ~changmin/Documents/.localized $targetVolume/Sync.localized/
	fi
	if [ ! -d $targetVolume/Archives.localized ]; then
		mkdir -p $targetVolume/Archives.localized
		cp -a ~changmin/Documents/.localized $targetVolume/Archives.localized/
	fi

	local optVerbose="-v"
	rsync -auz --delete $sourceVolume/Users/changmin/Documents/ $targetVolume/Sync.localized/Documents
	rsync -auz --delete $sourceVolume/Users/changmin/OneDrive/ $targetVolume/Sync.localized/OneDrive
	rsync -auz --delete $sourceVolume/Users/changmin/"Google Drive"/ $targetVolume/Sync.localized/"Google Drive"
	rsync -auz --delete $sourceVolume/Users/changmin/Developer.localized/ $targetVolume/Sync.localized/Developer.localized

	rsync -auz --delete $sourceVolume/Users/changmin/Archives.localized/ $targetVolume/Archives.localized
	rsync -auz $targetVolume/Archives.localized/ $sourceVolume/Users/changmin/Archives.localized

	# 카라비너 설정 백업
	rsync -auz --delete ~/bin/karabiner ~/Archives.localized/macOS/Karabiner
	rsync -auz --delete ~/bin/karabiner ~/Google\ Drive/Computer.localized/macOS
	#rsync -v -auz --delete ~/.config/karabiner ~/bin
}

backup $@
