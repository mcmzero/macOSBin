#!/bin/sh

sudo launchctl load /Library/LaunchDaemons/sysctl.plist
sudo sysctl -w kern.timer.coalescing_enabled=0
