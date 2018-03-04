#!/bin/sh
PATH_PLIST=~/Library/LaunchAgents/com.mcm.resetaudiobalance.plist
launchctl unload $PATH_PLIST
launchctl load $PATH_PLIST
/usr/bin/osascript -e "set volume input volume (1)" -e "set volume output volume (output volume of (get volume settings))"
