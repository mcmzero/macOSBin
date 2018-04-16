#!/bin/sh

SYSCTL_PLIST=/Library/LaunchDaemons/com.mcm.sysctl.plist

case $1 in
	on)
		#sudo sed -e's/kern.timer.coalescing_enabled=./kern.timer.coalescing_enabled=1/' -i '' $SYSCTL_PLIST
		sudo /usr/libexec/PlistBuddy -c "set :ProgramArguments:2 string kern.timer.coalescing_enabled=1" $SYSCTL_PLIST
		sudo /usr/libexec/PlistBuddy -c "set :RunAtLoad false" /Library/LaunchDaemons/com.mcm.sysctl.plist
		sudo launchctl unload -w $SYSCTL_PLIST
		sudo /usr/sbin/sysctl -w kern.timer.coalescing_enabled=1
	;;
	off)
		#sudo sed -e's/kern.timer.coalescing_enabled=./kern.timer.coalescing_enabled=0/' -i '' $SYSCTL_PLIST
		sudo /usr/libexec/PlistBuddy -c "set :ProgramArguments:2 string kern.timer.coalescing_enabled=0" $SYSCTL_PLIST
		sudo /usr/libexec/PlistBuddy -c "set :RunAtLoad true" /Library/LaunchDaemons/com.mcm.sysctl.plist
		sudo launchctl load -w $SYSCTL_PLIST
		sudo launchctl kickstart -k $SYSCTL_PLIST
		sudo /usr/sbin/sysctl -w kern.timer.coalescing_enabled=0
	;;
	*)
		echo "sysctl_timer_coalescing.sh {on|off}"
	;;
esac

#PlistBuddy Array
/usr/libexec/PlistBuddy -c "print :RunAtLoad" /Library/LaunchDaemons/com.mcm.sysctl.plist
/usr/libexec/PlistBuddy -c "print :ProgramArguments:2" $SYSCTL_PLIST
sysctl kern.timer.coalescing_enabled
