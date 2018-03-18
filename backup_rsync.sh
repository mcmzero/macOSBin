#!/bin/bash

SOURCE_VOLUME=/Volumes/macOS.localized
TARGET_VOLUME=/Volumes/Backup.localized

[ -d $TARGET_VOLUME/Sync.localized ] || (mkdir -p $TARGET_VOLUME/Sync.localized; cp -a ~changmin/Documents/.localized $TARGET_VOLUME/Sync.localized/)
[ -d $TARGET_VOLUME/Archives.localized ] || (mkdir -p $TARGET_VOLUME/Archives.localized; cp -a ~changmin/Documents/.localized $TARGET_VOLUME/Archives.localized/)

rsync -auzv --delete $SOURCE_VOLUME/Users/changmin/Documents/ $TARGET_VOLUME/Sync.localized/Documents
rsync -auzv --delete $SOURCE_VOLUME/Users/changmin/OneDrive/ $TARGET_VOLUME/Sync.localized/OneDrive
rsync -auzv --delete $SOURCE_VOLUME/Users/changmin/"Google Drive"/ $TARGET_VOLUME/Sync.localized/"Google Drive"
rsync -auzv --delete $SOURCE_VOLUME/Users/changmin/Developer.localized/ $TARGET_VOLUME/Sync.localized/Developer.localized

rsync -auzv --delete $SOURCE_VOLUME/Users/changmin/Archives.localized/ $TARGET_VOLUME/Archives.localized
rsync -auzv $TARGET_VOLUME/Archives.localized/ $SOURCE_VOLUME/Users/changmin/Archives.localized

# 카라비너 설정 백업
rsync -auzv ~/.config/karabiner ~/Archives.localized/macOS/Karabiner
rsync -auzv ~/.config/karabiner ~/Google\ Drive/Computer.localized/macOS
rsync -auzv ~/.config/karabiner ~/bin
