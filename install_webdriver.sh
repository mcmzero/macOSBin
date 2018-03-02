#!/bin/bash
# Simple script that download & install & patch(NVDARequiredOS) nvidia webdriver
# 2017.11.6 <changmin811@gmail.com>

PKG_FILE_VERSION_HIGH_SIERRA_17=387.10.10.10.25.159
PKG_OSVERSION_HIGHT_SIERRA_17=17D2012
#PKG_FILE_VERSION_HIGH_SIERRA_17=387.10.10.10.25.158
#PKG_OSVERSION_HIGHT_SIERRA_17=17D102

PKG_FILE_VERSION_SIERRA_16=378.05.05.25f06
PKG_OSVERSION_SIERRA_16=16G1212

SYSTEM_VERSION_FILE=/System/Library/CoreServices/SystemVersion.plist
NVDASTARTUPWEB_INFO=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist

OSVERSION=$(sw_vers -buildVersion)
MAJOR_NUMBER=$(echo $OSVERSION|cut -c 1-2)
if [ "$MAJOR_NUMBER" == "17" ]; then
        echo "macOS High Sierra ($OSVERSION)"
        PKG_FILE_VERSION=$PKG_FILE_VERSION_HIGH_SIERRA_17
        PKG_OSVERSION=$PKG_OSVERSION_HIGHT_SIERRA_17
elif [ "$MAJOR_NUMBER" == "16" ]; then
        echo "macOS Sierra ($OSVERSION)"
        NVDASTARTUPWEB_INFO=/System$NVDASTARTUPWEB_INFO
        PKG_FILE_VERSION=$PKG_FILE_VERSION_SIERRA_16
        PKG_OSVERSION=$PKG_OSVERSION_SIERRA_16
else
	echo "Unsupported OS"
	exit
fi

if [ "$1" != "" ]; then PKG_OSVERSION=$1; fi
PKG_FILE=WebDriver-${PKG_FILE_VERSION}.pkg
PKG_MAJOR_VERSION=$(echo $PKG_FILE_VERSION | cut -d . -f 1)
PKG_URL=https://images.nvidia.com/mac/pkg/${PKG_MAJOR_VERSION}/${PKG_FILE}

echo "Download & Install Nvidia $PKG_FILE"
sudo echo ""
if [ ! -f "$PKG_FILE" ]; then
        echo "Download: $PKG_URL"
        curl $PKG_URL --output $PKG_FILE || exit
        echo
fi

function set_ProductBuildVersion() {
        sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $@" $SYSTEM_VERSION_FILE
}

function print_ProductBuildVersion() {
        /usr/libexec/PlistBuddy -c "print ProductBuildVersion" $SYSTEM_VERSION_FILE
}

SYSCTL_OSVERSION=$(sysctl kern.osversion | cut -d ' ' -f2)
if [ "$OSVERSION" == "" ]; then
        set_ProductBuildVersion "$SYSCTL_OSVERSION"
        OSVERSION=$(sw_vers -buildVersion)
fi

if [ "$PKG_OSVERSION" != "$OSVERSION" ]; then
        echo "Change system build version: $OSVERSION -> $PKG_OSVERSION"
        set_ProductBuildVersion "$PKG_OSVERSION"
        SYSTEM_OSVERSION=$(print_ProductBuildVersion)
        echo "Check system build version: $SYSTEM_OSVERSION $(sw_vers -buildVersion)"
        echo
fi

if [ -f "$PKG_FILE" ]; then
        echo "Install package: sudo installer -pkg $PKG_FILE -target /"
        echo
        sudo installer -pkg $PKG_FILE -target /
        echo
fi

if [ "$PKG_OSVERSION" != "$OSVERSION" ]; then
        echo "Recover system build version: $PKG_OSVERSION -> $OSVERSION"
        set_ProductBuildVersion "$OSVERSION"
        SYSTEM_OSVERSION=$(print_ProductBuildVersion)
        echo "Check system build version: $SYSTEM_OSVERSION $(sw_vers -buildVersion)"
        echo
fi

function print_NVDARequiredOS() {
	/usr/libexec/PlistBuddy -c "print IOKitPersonalities:NVDAStartup:NVDARequiredOS" $NVDASTARTUPWEB_INFO
}

function set_NVDARequiredOS() {
	sudo /usr/libexec/PlistBuddy -c "set :IOKitPersonalities:NVDAStartup:NVDARequiredOS $@" $NVDASTARTUPWEB_INFO
	sudo chown -R root:wheel $NVDASTARTUPWEB_INFO
	#sudo codesign -f -s - $NVDASTARTUPWEB_INFO
}

if [ -f "$NVDASTARTUPWEB_INFO" ]; then
        BEFORE_NUMBER=$(print_NVDARequiredOS)
        set_NVDARequiredOS "$MAJOR_NUMBER"
        AFTER_NUMBER=$(print_NVDARequiredOS)
        echo "Patch NVDAStartupWeb.kext:NVDARequiredOS: $BEFORE_NUMBER -> $AFTER_NUMBER" && echo                               
        echo "Rebuild kextcahe: sudo kextcache -Boot -i /" && sudo kextcache -Boot -i / && echo
        rm "$PKG_FILE"
fi
