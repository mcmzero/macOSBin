#!/bin/bash

PKG_FILE_VERSION_HIGH_SIERRA_17=378.10.10.10.20.107
PKG_OSVERSION_HIGHT_SIERRA_17=17B48

PKG_FILE_VERSION_SIERRA_16=378.05.05.25f03
PKG_OSVERSION_SIERRA_16=16G1036

OSVERSION=$(sw_vers -buildVersion)
MAJOR_NUMBER=$(echo $OSVERSION|cut -c 1-2)

NVDASTARTUPWEB_INFO=/Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
if [ "${MAJOR_NUMBER}" == "17" ]; then
        echo "macOS High Sierra (${OSVERSION})"
        PKG_FILE_VERSION=${PKG_FILE_VERSION_HIGH_SIERRA_17}
        PKG_OSVERSION=${PKG_OSVERSION_HIGHT_SIERRA_17}
elif [ "${MAJOR_NUMBER}" == "16" ]; then
        echo "macOS Sierra (${OSVERSION})"
        NVDASTARTUPWEB_INFO=/System${NVDASTARTUPWEB_INFO}
        PKG_FILE_VERSION=${PKG_FILE_VERSION_SIERRA_16}
        PKG_OSVERSION=${PKG_OSVERSION_SIERRA_16}
else
	echo "미지원 os 버전 입니다."
	exit
fi

if [ "$1" != "" ]; then PKG_OSVERSION=$1; fi
PKG_FILE=WebDriver-${PKG_FILE_VERSION}.pkg
PKG_MAJOR_VERSION=$(echo $PKG_FILE_VERSION | cut -d . -f 1)
PKG_URL=https://images.nvidia.com/mac/pkg/${PKG_MAJOR_VERSION}/${PKG_FILE}

SYSTEM_VERSION_FILE=/System/Library/CoreServices/SystemVersion.plist
SYSCTL_OSVERSION=$(sysctl kern.osversion | cut -d ' ' -f2)
if [ "${OSVERSION}" == "" ]; then
        sudo sed -e "s/\<string\>${OSVERSION}\<\/string\>/\<string\>${SYSCTL_OSVERSION}\<\/string\>/" -i '' ${SYSTEM_VERSION_FILE}
        OSVERSION=$(sw_vers -buildVersion)
fi

echo "Nvidia ${PKG_FILE} 설치 스크립트 입니다."
sudo echo ""
if [ "${PKG_OSVERSION}" != "${OSVERSION}" ]; then
        echo "시스템 빌드번호 변경: ${OSVERSION} -> ${PKG_OSVERSION}"
        sudo sed -e "s/${OSVERSION}/${PKG_OSVERSION}/" -i '' ${SYSTEM_VERSION_FILE}
        SYSTEM_OSVERSION=$(grep ${PKG_OSVERSION} ${SYSTEM_VERSION_FILE} | cut -d "<" -f 2 | cut -d ">" -f 2)
        echo "시스템 빌드번호 확인: ${SYSTEM_OSVERSION} $(sw_vers -buildVersion)"
        echo
fi

if [ ! -f $PKG_FILE ]; then
        echo "패키지 다운로드: ${PKG_URL}"
        curl ${PKG_URL} --output ${PKG_FILE}
        echo
fi

if [ -f ${PKG_FILE} ]; then
        echo "패키지 설치: sudo installer -pkg ${PKG_FILE} -target /"
        echo
        sudo installer -pkg ${PKG_FILE} -target /
        echo
fi

if [ "${PKG_OSVERSION}" != "${OSVERSION}" ]; then
        echo "시스템 빌드번호 복구: ${PKG_OSVERSION} -> ${OSVERSION}"
        sudo sed -e "s/${PKG_OSVERSION}/${OSVERSION}/" -i '' ${SYSTEM_VERSION_FILE}
        SYSTEM_OSVERSION=$(grep ${OSVERSION} ${SYSTEM_VERSION_FILE} | cut -d "<" -f 2 | cut -d ">" -f 2)
        echo "시스템 빌드번호 확인: ${SYSTEM_OSVERSION} $(sw_vers -buildVersion)"
        echo
fi

if [ -f ${NVDASTARTUPWEB_INFO} ]; then
        BEFORE_NUMBER=$(grep ${MAJOR_NUMBER} ${NVDASTARTUPWEB_INFO} | cut -d "<" -f 2 | cut -d ">" -f 2)
        echo sudo sed -e "s/>${MAJOR_NUMBER}.*</>${MAJOR_NUMBER}</" -i '' ${NVDASTARTUPWEB_INFO}
        sudo sed -e "s/>${MAJOR_NUMBER}.*</>${MAJOR_NUMBER}</" -i '' ${NVDASTARTUPWEB_INFO}
        sudo chown -R root:wheel ${NVDASTARTUPWEB_INFO}
        AFTER_NUMBER=$(grep ${MAJOR_NUMBER} ${NVDASTARTUPWEB_INFO} | cut -d "<" -f 2 | cut -d ">" -f 2)
        echo "NVDAStartupWeb.kext 변경: ${BEFORE_NUMBER} -> ${AFTER_NUMBER}"
        echo                               
                                        
        echo "kextcahe 재생성: sudo kextcache -Boot -i /"
        sudo kextcache -Boot -i /
        echo

        rm ${PKG_FILE}
fi
