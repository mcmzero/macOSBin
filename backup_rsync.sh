#!/bin/bash

rsync -azv --delete ~/Documents/ /Volumes/Backup.localized/Documents/
rsync -azv --delete ~/OneDrive/ /Volumes/Backup.localized/OneDrive/
rsync -azv --delete ~/"Google Drive"/ /Volumes/Backup.localized/"Google Drive"/
rsync -azv --delete ~/Developer.localized/ /Volumes/Backup.localized/Developer.localized/
rsync -azv --delete ~/Archives.localized/ /Volumes/Backup.localized/Archives.localized/
