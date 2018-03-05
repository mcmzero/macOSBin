#!/bin/bash
# Simple script that download & install & patch(NVDARequiredOS) nvidia webdriver
# 2017.11.6 <changmin811@gmail.com>

PKG_MACOS_17=( \
        "387.10.10.10.25.159 17E160g 17D2102" \
        "387.10.10.10.25.158 17E160e 17D102" \
        "378.10.10.10.25.106 17C2205" \
)
PKG_DEFAULT_17=$((${#PKG_MACOS_17[@]} - 1))

PKG_MACOS_16=( \
        "378.05.05.25f06 16G1212" \
)
PKG_DEFAULT_16=$((${#PKG_MACOS_16[@]} - 1))

SYSTEM_VERSION_FILE=/System/Library/CoreServices/SystemVersion.plist
NVDASTARTUPWEB_INFO=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist

OSVERSION=$(sw_vers -buildVersion)
MAJOR_NUMBER=$(echo $OSVERSION|cut -c 1-2)

if [ "$MAJOR_NUMBER" == "17" ]; then
        PKG_MACOS=("${PKG_MACOS_17[@]}")
        PKG_DEFAULT=$PKG_DEFAULT_17
elif [ "$MAJOR_NUMBER" == "16" ]; then
        PKG_MACOS=("${PKG_MACOS_16[@]}")
        PKG_DEFAULT=$PKG_DEFAULT_16
        NVDASTARTUPWEB_INFO=/System$NVDASTARTUPWEB_INFO
else
	echo "Unsupported OS"
	exit
fi
unset -v PKG_MACOS_16 PKG_MACOS_17
unset PKG_DEFAULT_16 PKG_DEFAULT_17

#help
if [ "$1" == "-h" ]; then
        echo [PKG Version] [OS Version]
        echo [Install commands]
        echo
        for NUM in ${!PKG_MACOS[@]}; do
                echo ${PKG_MACOS[NUM]}
                echo \$ install_webdriver.sh $(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f 1 | cut -d '.' -f 6)
                echo
        done
        exit
fi

PKG_FILE_VERSION=$(echo ${PKG_MACOS[PKG_DEFAULT]} | cut -d ' ' -f 1)
PKG_OSVERSION=$(echo ${PKG_MACOS[PKG_DEFAULT]} | cut -d ' ' -f 2)
for NUM in ${!PKG_MACOS[@]}; do
        W=($(echo ${PKG_MACOS[NUM]}|wc -w))
        if [ "$1" != "" ]; then
                if [ "$1" == "$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f 1 | cut -d '.' -f 6)" ]; then
                        PKG_FILE_VERSION=$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f 1)
                        PKG_OSVERSION=$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f $W)
                        break
                fi
        else
                for FNUM in $(eval echo {2..$W}); do
                        if [ "$OSVERSION" == "$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f $FNUM)" ]; then
                                PKG_FILE_VERSION=$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f 1)
                                PKG_OSVERSION=$(echo ${PKG_MACOS[NUM]} | cut -d ' ' -f $W)
                                break
                        fi
                done
        fi
done
echo "macOS ($OSVERSION) : $PKG_FILE_VERSION ($PKG_OSVERSION)"

cd $HOME/Downloads
PKG_FILE=WebDriver-${PKG_FILE_VERSION}.pkg
PKG_MAJOR_VERSION=$(echo $PKG_FILE_VERSION | cut -d . -f 1)
PKG_URL=https://images.nvidia.com/mac/pkg/${PKG_MAJOR_VERSION}/${PKG_FILE}

echo "Download & Install Nvidia $PKG_FILE"
sudo echo ""
if ! pkgutil --check-signature $PKG_FILE &> /dev/null; then
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

if [ "$OSVERSION" == "" ]; then
        set_ProductBuildVersion $(sysctl kern.osversion | cut -d ' ' -f 2)
        OSVERSION=$(sw_vers -buildVersion)
fi

# install pkg
if [ -f "$PKG_FILE" ]; then
        if [ "$PKG_OSVERSION" != "$OSVERSION" ]; then
                echo "Change system build version: $OSVERSION -> $PKG_OSVERSION"
                set_ProductBuildVersion "$PKG_OSVERSION"
                SYSTEM_OSVERSION=$(print_ProductBuildVersion)
                echo "Check system build version: $SYSTEM_OSVERSION $(sw_vers -buildVersion)"
                echo
        fi
        #echo "Install package: sudo installer -pkg $PKG_FILE -target /"
        sudo installer -pkg $PKG_FILE -target /
        echo
        if [ "$PKG_OSVERSION" != "$OSVERSION" ]; then
                echo "Recover system build version: $PKG_OSVERSION -> $OSVERSION"
                set_ProductBuildVersion "$OSVERSION"
                SYSTEM_OSVERSION=$(print_ProductBuildVersion)
                echo "Check system build version: $SYSTEM_OSVERSION $(sw_vers -buildVersion)"
                echo
        fi
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
        #rm "$PKG_FILE"
fi
