#!/bin/sh

sudo find /private/var/folders/ -name com.apple.dock.iconcache -exec rm -rf {} \;
sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \;
#sudo mv /Library/Caches/com.apple.iconservices.store com.apple.ic
