#!/bin/sh

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems"
WOW_PATH="/Volumes/Archives/Applications/Games/World of Warcraft"
BAK_PATH="/Volumes/Archives/Google Drive/게임/wow"
tar cvzf "${BAK_PATH}/AccountBackup/Account.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/WTF" Account
tar cvzf "${BAK_PATH}/AddOnsBackup/AddOns.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/Interface" AddOns
