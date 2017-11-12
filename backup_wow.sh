#!/bin/sh
WOW_PATH="/Applications/Games/World of Warcraft"
BAK_PATH="$HOME/drv/게임/wow"

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems"
tar cvzf "${BAK_PATH}/AccountBackup/Account.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/WTF" Account
tar cvzf "${BAK_PATH}/AddOnsBackup/AddOns.tgz" ${EXCLUDE_TAR} -C "${WOW_PATH}/Interface" AddOns
