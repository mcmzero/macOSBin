#!/bin/sh

cd $(sudo find /private/var/folders -name com.apple.dock.launchpad)/db
sqlite3 db "SELECT * FROM downloading_apps;”
sqlite3 db "DELETE FROM downloading_apps;”
sudo killall Dock
