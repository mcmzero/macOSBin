#!/bin/sh

WOW_PATH=~/Games/World\ of\ Warcraft
tar cvzf "${WOW_PATH}/WTF/AccountBackup/Account.tgz" -C "${WOW_PATH}/WTF" Account
tar cvzf "${WOW_PATH}/Interface/AddOnsBackup/AddOns.tgz" -C "${WOW_PATH}/Interface" AddOns
