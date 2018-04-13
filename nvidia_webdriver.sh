#!/bin/bash
#
# Simple script that download & install & patch(NVDARequiredOS) nvidia webdriver
# 2017.11.6 <changmin811@gmail.com>

osVersion=$(sw_vers -buildVersion)
osMajorNumber=$(echo $osVersion|cut -c 1-2)

nvdaStartupWebInfo=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
if [ ! -f "$nvdaStartupWebInfo" ]; then
	[ -f "/System$nvdaStartupWebInfo" ] && nvdaStartupWebInfo=/System$nvdaStartupWebInfo
fi

declare -a pkgMacOs
declare -a pkgMacOsBeta=(\
	"387.10.10.10.30.103 17F35e 17E199"\
)

function initPkgList() {
	echo "Downloading webdriver list from https://gfe.nvidia.com/mac-update"
	local tempfile=$(mktemp -q -t gfe_nvidia_mac_update.XXX)
	curl -s "https://gfe.nvidia.com/mac-update" > $tempfile
	
	declare -a gfeVersion=($(/usr/libexec/PlistBuddy -c "print :updates" $tempfile | grep version | cut -d '=' -f 2))
	declare -a gfeOs=($(/usr/libexec/PlistBuddy -c "print :updates" $tempfile | grep OS | cut -d '=' -f 2))
	for n in ${!gfeOs[@]}; do
		pkgMacOs[n]="${gfeVersion[n]} ${gfeOs[n]}"
	done
	
	pkgMacOs=("${pkgMacOsBeta[@]}" "${pkgMacOs[@]}")
	pkgMacOsMax=${#pkgMacOs[@]}
	pkgMacOsDefault=0

	unset -v gfeVersion gfeOs pkgMacOsBeta
	rm -f $tempfile
}

function getPkgVersion() {
	local pkgIndex
	local pkgLastField

	for n in ${!pkgMacOs[@]}; do
		if [ "$1" ]; then
			local iterOsVersion="$(echo ${pkgMacOs[n]}|cut -d' ' -f2)"
			if [ "$iterOsVersion" == "$1" ]; then
				pkgIndex=$n
			else
				for fieldIndex in {1..6}; do
					local pkgVersion="$(echo ${pkgMacOs[n]}|cut -d' ' -f1|cut -d'.' -f${fieldIndex}-)"
					if [ "$pkgVersion" == "$1" ]; then
						pkgIndex=$n
						break
					fi
				done
			fi
		else
			fieldIndexMax=($(echo ${pkgMacOs[n]} | wc -w))
			for ((fieldIndex = 2; fieldIndex <= $fieldIndexMax; fieldIndex++)); do
				if [ "$osVersion" == "$(echo ${pkgMacOs[n]} | cut -d' ' -f${fieldIndex})" ]; then
					pkgIndex=$n
					break
				fi
			done
		fi
		[ "$pkgIndex" ] && break
	done

	[ "$pkgIndex" ] || pkgIndex=pkgMacOsDefault

	fieldIndexMax=($(echo ${pkgMacOs[pkgIndex]} | wc -w))
	pkgOsVersion=$(echo ${pkgMacOs[pkgIndex]} | cut -d' ' -f${fieldIndexMax})
	pkgFileVersion=$(echo ${pkgMacOs[pkgIndex]} | cut -d' ' -f1)
	pkgInstalledVersion=$(/usr/libexec/PlistBuddy -c 'print :CFBundleGetInfoString' /Library/Extensions/GeForceWeb.kext/Contents/Info.plist | cut -d' ' -f3-)

	echo "System's driver: WebDriver-$pkgInstalledVersion ($osVersion)"
	[ "$1" ] && echo "Searched driver: WebDriver-$(echo ${pkgMacOs[pkgIndex]}|cut -d' ' -f1-) ($1)"\
			|| echo "Searched driver: WebDriver-$pkgFileVersion ($pkgOsVersion)"
}

function downloadPkg() {
	pkgFileName=WebDriver-${pkgFileVersion}.pkg
	pkgMajorVersion=$(echo $pkgFileVersion | cut -d . -f 1)
	
	sudo echo "Enter passwords for edit /System/Library/CoreServices/SystemVersion.plist"
	echo "Download & Install Nvidia $pkgFileName"

	cd $HOME/Downloads	
	[ -d "webdrivers" ] && cd "webdrivers"
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
	if [ -z "$osVersion" ]; then
		setProdcutBuildVersion $(sysctl kern.osVersion | cut -d' ' -f2)
		osVersion=$(sw_vers -buildVersion)
	fi
}

function installPkg() {
	[ -f "$pkgFileName" ] || return 1

	if [ "$pkgOsVersion" != "$osVersion" ]; then
		echo "Change system build version: $osVersion -> $pkgOsVersion"
		setProdcutBuildVersion "$pkgOsVersion"
		echo "System build version1: $(printProductBuildVersion)"
		echo "System build version2: $(sw_vers -buildVersion)"
	fi
	
	sudo installer -pkg $pkgFileName -target /
	ret=$?
	pkgInstalledVersion=$(/usr/libexec/PlistBuddy -c 'print :CFBundleGetInfoString' /Library/Extensions/GeForceWeb.kext/Contents/Info.plist | cut -d' ' -f3-)
	echo "Installed pkg version: $pkgInstalledVersion"

	if [ "$pkgOsVersion" != "$osVersion" ]; then
		echo "Recover system build version: $pkgOsVersion -> $osVersion"
		setProdcutBuildVersion "$osVersion"
		echo "System build version1: $(printProductBuildVersion)"
		echo "System build version2: $(sw_vers -buildVersion)"
	fi
	
	return $ret
}

function printNVDARequiredOS() {
	/usr/libexec/PlistBuddy -c "print :IOKitPersonalities:NVDAStartup:NVDARequiredOS" $nvdaStartupWebInfo
}

function setNVDARequiredOS() {
	sudo /usr/libexec/PlistBuddy -c "set :IOKitPersonalities:NVDAStartup:NVDARequiredOS $@" $nvdaStartupWebInfo \
	&& sudo chown -R root:wheel $nvdaStartupWebInfo
}

function patchNVDARequredOS() {
	if [ -f "$nvdaStartupWebInfo" ]; then
		beforeNumber=$(printNVDARequiredOS)
		setNVDARequiredOS "$osMajorNumber"
		afterNumber=$(printNVDARequiredOS)
		echo "Patch NVDAStartupWeb.kext:NVDARequiredOS: $beforeNumber -> $afterNumber"
	fi
}

function rebuildKernelCache() {
	echo "Rebuild kextcahe: sudo kextcache -Boot -i /"
	sudo kextcache -Boot -i /
}

function run() {
	case $1 in
		-s)
			[ "$2" ] && sudo /usr/libexec/PlistBuddy -c "set :ProductBuildVersion $2" /System/Library/CoreServices/SystemVersion.plist
			/usr/libexec/PlistBuddy -c "print :ProductBuildVersion" /System/Library/CoreServices/SystemVersion.plist
		;;
		-l)
			initPkgList
			for n in ${!pkgMacOs[@]}; do
				echo ${pkgMacOs[pkgMacOsMax-n-1]}
			done
		;;
		-h)
			basename=$(basename $0)
			echo $basename '{-h|-l|-u} {pkg version | os build version}'
			echo
			echo '# Show driver version list'
			echo $basename -l
			echo
			echo '# upgrade only'
			echo $basename -u
			echo
			echo '# Install pkg with pkg version or os build version'
			echo $basename 387.10.10.10.30.103
			echo $basename 30.103
			echo $basename 103
			echo $basename 17E199
			echo
			echo '# Install default web driver'
			echo $basename
			echo
		;;
		-u)
			#only for upgrade
			shift
			initPkgList
			getPkgVersion $@
			[ "${pkgInstalledVersion//./}" -ge "${pkgFileVersion//./}" ] && return 1
			[ "$pkgFileVersion" == "$pkgInstalledVersion" ] && return 1
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
