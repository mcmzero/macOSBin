#!/bin/bash
#
# Simple script that download & install & patch(NVDARequiredOS) nvidia webdriver
# 2017.11.6 <changmin811@gmail.com>

declare -a pkgMacOs

function initPkgList() {
    osVersion=$(sw_vers -buildVersion)
    osMajorNumber=$(echo $osVersion|cut -c 1-2)
    
    local pkgMacOsBeta=(\
        "378.10.10.10.25.106 17C2205"\
		"387.10.10.10.30.103 17F35e 17E199"\
    )
    
    echo "Downloading webdriver list from https://gfe.nvidia.com/mac-update"
    
    local tempfile=$(mktemp -q -t gfe_nvidia_mac_update.XXX)
    curl -s "https://gfe.nvidia.com/mac-update" > $tempfile
    
    declare -a gfeVersion=($(/usr/libexec/PlistBuddy -c "print :updates" $tempfile | grep version | cut -d '=' -f 2))
    declare -a gfeOs=($(/usr/libexec/PlistBuddy -c "print :updates" $tempfile | grep OS | cut -d '=' -f 2))
    
    for idx in ${!gfeOs[@]}; do
        pkgMacOs[idx]="${gfeVersion[idx]} ${gfeOs[idx]}"
    done
    
	#pkgMacOs=("${pkgMacOs[@]}" "${pkgMacOsBeta[@]}")
	pkgMacOsMax=${#pkgMacOs[@]}
	pkgMacOsDefault=0
    
    unset -v gfeVersion gfeOs pkgMacOsBeta
    rm -f $tempfile
}

function getPkgVersion() {
    local lastIdx=($(echo ${pkgMacOs[pkgMacOsDefault]} | wc -w))
    pkgOsVersion=$(echo ${pkgMacOs[pkgMacOsDefault]} | cut -d ' ' -f $lastIdx)
    pkgFileVersion=$(echo ${pkgMacOs[pkgMacOsDefault]} | cut -d ' ' -f 1)
    pkgInstalledVersion=$(/usr/libexec/PlistBuddy -c "print :CFBundleGetInfoString" /Library/Extensions/GeForceWeb.kext/Contents/Info.plist | cut -d' ' -f3)
    
    for idx in ${!pkgMacOs[@]}; do
        lastIdx=($(echo ${pkgMacOs[idx]} | wc -w))
        if [ "$1" != "" ]; then
            if [ "$1" == "$(echo ${pkgMacOs[idx]} | cut -d ' ' -f 1 | cut -d '.' -f 6)" ]; then
                pkgFileVersion=$(echo ${pkgMacOs[idx]} | cut -d ' ' -f 1)
                pkgOsVersion=$(echo ${pkgMacOs[idx]} | cut -d ' ' -f $lastIdx)
                break
            fi
        else
            for fieldIdx in $(eval echo {2..$lastIdx}); do
                if [ "$osVersion" == "$(echo ${pkgMacOs[idx]} | cut -d ' ' -f $fieldIdx)" ]; then
                    pkgFileVersion=$(echo ${pkgMacOs[idx]} | cut -d ' ' -f 1)
                    pkgOsVersion=$(echo ${pkgMacOs[idx]} | cut -d ' ' -f $lastIdx)
                    break
                fi
            done
        fi
    done
    
    echo "macOS ($osVersion) : $pkgFileVersion ($pkgOsVersion)"
}

function downloadPkg() {
    pkgFileName=WebDriver-${pkgFileVersion}.pkg
    pkgMajorVersion=$(echo $pkgFileVersion | cut -d . -f 1)
    
    sudo echo "Enter passwords for edit /System/Library/CoreServices/SystemVersion.plist"
    echo "Download & Install Nvidia $pkgFileName"
    
    cd $HOME/Downloads
    if ! pkgutil --check-signature $pkgFileName &> /dev/null; then
        local pkgUrl="https://images.nvidia.com/mac/pkg/${pkgMajorVersion}/${pkgFileName}"
        echo "Download: $pkgUrl"
        curl $pkgUrl --output $pkgFileName
        pkgutil --check-signature $pkgFileName &> /dev/null || return 1
    fi
}

function setProdcutBuildVersion() {
    sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $@" /System/Library/CoreServices/SystemVersion.plist
    return $?
}

function printProductBuildVersion() {
    /usr/libexec/PlistBuddy -c "print :ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist
    return $?
}

function checkOsVersion() {
    if [ "$osVersion" == "" ]; then
        setProdcutBuildVersion $(sysctl kern.osVersion | cut -d ' ' -f 2)
        osVersion=$(sw_vers -buildVersion)
    fi
}

function installPkg() {
    local ret=1
    if [ ! -f "$pkgFileName" ]; then
        return $ret
    fi
    
    if [ "$pkgOsVersion" != "$osVersion" ]; then
        echo "Change system build version: $osVersion -> $pkgOsVersion"
        setProdcutBuildVersion "$pkgOsVersion"
        local systemOsVersion=$(printProductBuildVersion)
        echo "Check system build version: $systemOsVersion $(sw_vers -buildVersion)"
    fi
    
    sudo installer -pkg $pkgFileName -target / && ret=0
    
    if [ "$pkgOsVersion" != "$osVersion" ]; then
        echo "Recover system build version: $pkgOsVersion -> $osVersion"
        setProdcutBuildVersion "$osVersion"
        local systemOsVersion=$(printProductBuildVersion)
        echo "Check system build version: $systemOsVersion $(sw_vers -buildVersion)"
    fi
    
    return $ret
}

function printNVDARequiredOS() {
    if [ ! -f "$nvdaStartupWebInfo" ]; then
        [ -f "/System$nvdaStartupWebInfo" ] && nvdaStartupWebInfo=/System$nvdaStartupWebInfo
    fi
    /usr/libexec/PlistBuddy -c "print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" $nvdaStartupWebInfo
}

function setNVDARequiredOS() {
    if [ ! -f "$nvdaStartupWebInfo" ]; then
        [ -f "/System$nvdaStartupWebInfo" ] && nvdaStartupWebInfo=/System$nvdaStartupWebInfo
    fi
    sudo /usr/libexec/PlistBuddy -c "set :IOKitPersonalities:NVDAStartup:NVDARequiredOS $@" $nvdaStartupWebInfo
    sudo chown -R root:wheel $nvdaStartupWebInfo
}

function patchNVDARequredOS() {
    nvdaStartupWebInfo=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
    if [ -f "$nvdaStartupWebInfo" ]; then
        beforeNumber=$(printNVDARequiredOS)
        setNVDARequiredOS "$osMajorNumber"
        afterNumber=$(printNVDARequiredOS)
        echo "Patch NVDAStartupWeb.kext:NVDARequiredOS: $beforeNumber -> $afterNumber"
        #rm "$pkgFileName"
    fi
}

function rebuildKernelCache() {
    echo "Rebuild kextcahe: sudo kextcache -Boot -i /"
    sudo kextcache -Boot -i /
}

function run() {
    case $1 in
        -s)
            [ "$2" != "" ] && sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $2" /System/Library/CoreServices/SystemVersion.plist
            /usr/libexec/PlistBuddy -c "print :ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist
        ;;
        -l)
            initPkgList
            for n in ${!pkgMacOs[@]}; do
                echo ${pkgMacOs[pkgMacOsMax-n-1]}
            done
        ;;
        -h)
            echo [PKG Version] [OS Version]
            echo [Install commands]
            echo
            initPkgList
            for n in ${!pkgMacOs[@]}; do
                echo ${pkgMacOs[pkgMacOsMax-n-1]}
                echo \$ install_webdriver.sh $(echo ${pkgMacOs[pkgMacOsMax-n-1]} | cut -d ' ' -f 1 | cut -d '.' -f 6)
                echo
            done
        ;;
        -u)
			#only for update
			shift
            initPkgList
            getPkgVersion $@
            if [ "$pkgFileVersion" == "$pkgInstalledVersion" ]; then
                echo "$pkgInstalledVersion" is already installed
                return 1
            fi
            if ! downloadPkg; then
                echo "Download failed"
                return 1
            fi
            checkOsVersion
            if ! installPkg; then
                patchNVDARequredOS
                echo "Installation failed"
                return 1
            fi
            patchNVDARequredOS
            rebuildKernelCache
        ;;
        *)
            initPkgList
            getPkgVersion $@
            if ! downloadPkg; then
                echo "Download failed"
                return 1
            fi
            checkOsVersion
            if ! installPkg; then
                patchNVDARequredOS
                echo "Installation failed"
                return 1
            fi
            patchNVDARequredOS
            rebuildKernelCache
        ;;
    esac
}

run $@
