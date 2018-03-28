#!/bin/bash
# Simple script that patch NVDARequiredOS of nvidia webdriver 
# 2017.12.1 <changmin811@gmail.com>

OSVERSION=$(sw_vers -buildVersion)
MAJOR_NUMBER=$(echo $OSVERSION|cut -c 1-2)

NVDASTARTUPWEB_INFO=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
function get_path_nvdastartupweb_info() {
	if [ "$MAJOR_NUMBER" == "17" ]; then
			echo "macOS High Sierra ($OSVERSION)"
	elif [ "$MAJOR_NUMBER" == "16" ]; then
			echo "macOS Sierra ($OSVERSION)"
			NVDASTARTUPWEB_INFO=/System$NVDASTARTUPWEB_INFO
	else
		echo "Unsupported OS"
		exit
	fi
}

function print_NVDARequiredOS() {
        /usr/libexec/PlistBuddy -c "print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" $NVDASTARTUPWEB_INFO
}

function set_NVDARequiredOS() {
        sudo /usr/libexec/PlistBuddy -c "set :IOKitPersonalities:NVDAStartup:NVDARequiredOS $@" $NVDASTARTUPWEB_INFO
        sudo chown -R root:wheel $NVDASTARTUPWEB_INFO
}

echo "Patch NVDARequiredOS on $NVDASTARTUPWEB_INFO"
sudo echo ""

get_path_nvdastartupweb_info
if [ -f "$NVDASTARTUPWEB_INFO" ]; then
        BEFORE_NUMBER=$(print_NVDARequiredOS)
        set_NVDARequiredOS "$MAJOR_NUMBER"
        AFTER_NUMBER=$(print_NVDARequiredOS)
        echo "Patch NVDAStartupWeb.kext:NVDARequiredOS: $BEFORE_NUMBER -> $AFTER_NUMBER" && echo                               
        echo "Rebuild kextcahe: sudo kextcache -Boot -i /" && sudo kextcache -Boot -i / && echo
fi
