#!/bin/bash

SOURCE_VOLUME=/Volumes/Backup.localized
#TARGET_VOLUME=/Volumes/macOS.localized
TARGET_VOLUME=/Volumes/Sierra.localized

[ -d /Volumes/Backup.localized/Sync.localized ] || mkdir -p /Volumes/Backup.localized/Sync.localized
rsync -auzv --delete /Volumes/Backup.localized/Sync.localized/Documents/ $TARGET_VOLUME/Users/changmin/Documents
rsync -auzv --delete /Volumes/Backup.localized/Sync.localized/OneDrive/ $TARGET_VOLUME/Users/changmin/OneDrive
rsync -auzv --delete /Volumes/Backup.localized/Sync.localized/"Google Drive"/ $TARGET_VOLUME/Users/changmin/"Google Drive"
rsync -auzv --delete /Volumes/Backup.localized/Sync.localized/Developer.localized/ $TARGET_VOLUME/Users/changmin/Developer.localized
rsync -auzv --delete /Volumes/Backup.localized/Archives.localized/ $TARGET_VOLUME/Users/changmin/Archives.localized

# 카라비너 설정 백업
rsync -auzv ~/.config/karabiner ~/Archives.localized/macOS/Karabiner
rsync -auzv ~/.config/karabiner ~/Google\ Drive/Computer.localized/macOS
