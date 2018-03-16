#!/bin/bash
# Simple script that download & install & patch(NVDARequiredOS) nvidia webdriver
# 2017.11.6 <changmin811@gmail.com>

if [ "$1" == "-s" ]; then
        [ "$2" != "" ] && sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $2" /System/Library/CoreServices/SystemVersion.plist
        /usr/libexec/PlistBuddy -c "print ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist
        exit
fi

OSVERSION=$(sw_vers -buildVersion)
OS_MAJOR_NUMBER=$(echo $OSVERSION|cut -c 1-2)

PKG_MACOS_BETA=( \
        "387.10.10.10.25.160 17E170c 17E160g 17D2102" \
        "387.10.10.10.25.161 17E182a 17E161c 17E160e 17D102" \
        "378.10.10.10.25.106 17C2205" \
)

echo "Downloading webdriver list from https://gfe.nvidia.com/mac-update"
tempfile=`mktemp -q -t gfe_nvidia_mac_update`
curl -s https://gfe.nvidia.com/mac-update > $tempfile
declare -a gfe_version=($(/usr/libexec/PlistBuddy -c "print updates" $tempfile | grep version | cut -d '=' -f 2))
declare -a gfe_os=($(/usr/libexec/PlistBuddy -c "print updates" $tempfile | grep OS | cut -d '=' -f 2))
rm -f $tempfile

declare -a PKG_MACOS
for idx in ${!gfe_os[@]}; do
    PKG_MACOS[idx]="${gfe_version[idx]} ${gfe_os[idx]}"
done
PKG_MACOS=("${PKG_MACOS[@]}" "${PKG_MACOS_BETA[@]}")
unset -v gfe_version gfe_os PKG_MACOS_BETA
PKG_DEFAULT=${#PKG_MACOS[@]}
echo

if [ "$1" == "-l" ]; then
        for pkg in ${!PKG_MACOS[@]}; do
            echo ${PKG_MACOS[pkg]}
        done
        exit
fi
if [ "$1" == "-h" ]; then
        echo [PKG Version] [OS Version]
        echo [Install commands]
        echo
        for idx in ${!PKG_MACOS[@]}; do
                echo ${PKG_MACOS[idx]}
                echo \$ install_webdriver.sh $(echo ${PKG_MACOS[idx]} | cut -d ' ' -f 1 | cut -d '.' -f 6)
                echo
        done
        exit
fi

#default value
lastIdx=($(echo ${PKG_MACOS[PKG_DEFAULT-2]} | wc -w))
PKG_FILE_VERSION=$(echo ${PKG_MACOS[PKG_DEFAULT-2]} | cut -d ' ' -f 1)
PKG_OSVERSION=$(echo ${PKG_MACOS[PKG_DEFAULT-2]} | cut -d ' ' -f $lastIdx)

for idx in ${!PKG_MACOS[@]}; do
        lastIdx=($(echo ${PKG_MACOS[idx]} | wc -w))
        if [ "$1" != "" ]; then
                if [ "$1" == "$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f 1 | cut -d '.' -f 6)" ]; then
                        PKG_FILE_VERSION=$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f 1)
                        PKG_OSVERSION=$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f $lastIdx)
                        break
                fi
        else
                for fieldIdx in $(eval echo {2..$lastIdx}); do
                        if [ "$OSVERSION" == "$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f $fieldIdx)" ]; then
                                PKG_FILE_VERSION=$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f 1)
                                PKG_OSVERSION=$(echo ${PKG_MACOS[idx]} | cut -d ' ' -f $lastIdx)
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
        sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $@" /System/Library/CoreServices/SystemVersion.plist
}

function print_ProductBuildVersion() {
        /usr/libexec/PlistBuddy -c "print ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist
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

NVDASTARTUPWEB_INFO=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
function print_NVDARequiredOS() {
        if [ ! -f "$NVDASTARTUPWEB_INFO" ]; then
                [ -f "/System$NVDASTARTUPWEB_INFO" ] && NVDASTARTUPWEB_INFO=/System$NVDASTARTUPWEB_INFO
        fi
	/usr/libexec/PlistBuddy -c "print IOKitPersonalities:NVDAStartup:NVDARequiredOS" $NVDASTARTUPWEB_INFO
}

function set_NVDARequiredOS() {
        if [ ! -f "$NVDASTARTUPWEB_INFO" ]; then
                [ -f "/System$NVDASTARTUPWEB_INFO" ] && NVDASTARTUPWEB_INFO=/System$NVDASTARTUPWEB_INFO
        fi
	sudo /usr/libexec/PlistBuddy -c "set :IOKitPersonalities:NVDAStartup:NVDARequiredOS $@" $NVDASTARTUPWEB_INFO
	sudo chown -R root:wheel $NVDASTARTUPWEB_INFO
	#sudo codesign -f -s - $NVDASTARTUPWEB_INFO
}

BEFORE_NUMBER=$(print_NVDARequiredOS)
if [ -f "$NVDASTARTUPWEB_INFO" ]; then
        set_NVDARequiredOS "$OS_MAJOR_NUMBER"
        AFTER_NUMBER=$(print_NVDARequiredOS)
        echo "Patch NVDAStartupWeb.kext:NVDARequiredOS: $BEFORE_NUMBER -> $AFTER_NUMBER" && echo                               
        echo "Rebuild kextcahe: sudo kextcache -Boot -i /" && sudo kextcache -Boot -i / && echo
        #rm "$PKG_FILE"
fi
