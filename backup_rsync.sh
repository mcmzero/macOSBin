#!/bin/bash

rsync -azv --delete ~/Documents/ /Volumes/Backup.localized/Sync.localized/Documents
rsync -azv --delete ~/OneDrive/ /Volumes/Backup.localized/Sync.localized/OneDrive
rsync -azv --delete ~/"Google Drive"/ /Volumes/Backup.localized/Sync.localized/"Google Drive"
rsync -azv --delete ~/Developer.localized/ /Volumes/Backup.localized/Sync.localized/Developer.localized
rsync -azv --delete ~/Archives.localized/ /Volumes/Backup.localized/Archives.localized

#rsync -azv /Volumes/Backup.localized/Archives.localized/ ~/Archives.localized
