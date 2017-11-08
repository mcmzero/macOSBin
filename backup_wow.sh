#!/bin/sh

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems"
#WOW_PATH=/Volumes/Applications/World\ of\ Warcraft
WOW_PATH=/Users/changmin/wow
tar cvzf "${WOW_PATH}/WTF/AccountBackup/Account.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/WTF" Account
tar cvzf "${WOW_PATH}/Interface/AddOnsBackup/AddOns.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/Interface" AddOns
