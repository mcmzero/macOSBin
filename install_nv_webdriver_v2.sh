#!/bin/sh

FAKEVERSION=$1
if [ "${FAKEVERSION}" == "" ];
then
        FAKEVERSION=17B48
fi

#OSVERSION=$(sysctl kern.osversion | awk '{ print $2 }')
OSVERSION=$(sw_vers -buildVersion)

echo "잠시 시스템 빌드번호 ${OSVERSION}를${FAKEVERSION}로 변경합니다"
sudo sed -e "s/$OSVERSION/$FAKEVERSION/" -i '' /System/Library/CoreServices/SystemVersion.plist
SYSTEM_VERSION=$(grep $FAKEVERSION /System/Library/CoreServices/SystemVersion.plist | cut -d "<" -f 2 | cut -d ">" -f 2)
echo "시스템 버전 확인: $SYSTEM_VERSION"
echo

WEBDRIVER_FILE=$(ls -tr WebDriver-*.pkg | head -n 1)
WEBDRIVER_PKG=$(echo $WEBDRIVER_FILE | cut -d "." -f 7)
if [ "$WEBDRIVER_PKG" == "pkg" ]; then
	echo "패키지 파일 ${WEBDRIVER_FILE}를 찾았습니다."
	echo "다음 명령으로 설치를 진행합니다."
	echo "sudo installer -pkg $WEBDRIVER_FILE -target /"
	echo
	sudo installer -pkg $WEBDRIVER_FILE -target /
else
	echo "웹드라이버 패키지를 실행 하세요."
	sleep 3
	echo

	echo "웹드라이버 설치에서 \"재시작\" 버튼이 나오면 여기에 \"엔터\"를 치세요."
	read
fi

echo "다시 시스템 빌드번호 ${FAKEVERSION}에서 ${OSVERSION}로 복구합니다"
sudo sed -e "s/$FAKEVERSION/$OSVERSION/" -i '' /System/Library/CoreServices/SystemVersion.plist
SYSTEM_VERSION=$(grep $OSVERSION /System/Library/CoreServices/SystemVersion.plist | cut -d "<" -f 2 | cut -d ">" -f 2)
echo "시스템 버전 확인: $SYSTEM_VERSION"
echo

BEFORE_NUMBER=$(grep 17 /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist | cut -d "<" -f 2 | cut -d ">" -f 2)
sudo sed -e 's/>17.*</>17</' -i '' /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
sudo chown -R root:wheel /Library/Extensions/NVDAStartupWeb.kext
AFTER_NUMBER=$(grep 17 /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist | cut -d "<" -f 2 | cut -d ">" -f 2)
echo "NVDAStartupWeb.kext: 변경전(${BEFORE_NUMBER}), 변경후(${AFTER_NUMBER})"
echo

echo "kextcahe 재생성: "
sudo kextcache -Boot -i /

if [ "$WEBDRIVER_PKG" == "pkg" ]; then
	read -p "시스템을 재시작 하겠습니까? (y/N): " choice
	case "$choice" in
	[yY]* )
	echo "시스템을 재시작합니다."
	sleep 3
	sudo reboot
	;;
	* )
	echo "작업을 종료합니다."
	sleep 3
	;;
	esac
fi
