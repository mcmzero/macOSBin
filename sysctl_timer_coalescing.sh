#!/bin/sh

SYSCTL_PLIST=/Library/LaunchDaemons/sysctl.plist

if [ "$1" == "on" ]; then
	sudo sed -e 's/=0/=1/' -i '' $SYSCTL_PLIST
	sudo launchctl unload $SYSCTL_PLIST
	sudo launchctl load $SYSCTL_PLIST
	sysctl kern.timer.coalescing_enabled
elif [ "$1" == "off" ]; then
        sudo sed -e 's/=1/=0/' -i '' $SYSCTL_PLIST
        sudo launchctl unload $SYSCTL_PLIST
        sudo launchctl load $SYSCTL_PLIST
        sysctl kern.timer.coalescing_enabled
else
	echo "sysctl_timer_coalescing.sh {on|off}"
	sysctl kern.timer.coalescing_enabled
fi
