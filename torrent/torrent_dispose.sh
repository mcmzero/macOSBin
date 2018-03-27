#!/bin/bash
# torrent_dispose.sh <changmin811@gmail.com>

movieFolderName="동영상"
dropboxFolderName="떨굼상자"

RASPI_torrentSourcePath="/mnt/rasPiTorrent/torrent"
RASPI_torrentTargetPath="$RASPI_torrentSourcePath/$movieFolderName"
RASPI_torrentDropboxPath="$RASPI_torrentSourcePath/$dropboxFolderName"

MCM_torrentSourcePath="/Share/rasPiTorrent/torrent"
MCM_torrentTargetPath="$MCM_torrentSourcePath/$movieFolderName"
MCM_torrentDropboxPath="$MCM_torrentSourcePath/$dropboxFolderName"

MCM_imacSourcePath="$HOME/Downloads"
MCM_imacTargetPath="$HOME/Downloads"

[ "${HOSTNAME::4}" == "iMac" ] && SAY_MODE=ON

function rmdirSub() {
	if [ -d "$1" ]; then
		cd "$1"
		for file in $(ls -a 2> /dev/null); do
			if [ "$file" == "." ] || [ "$file" == ".." ]; then
				continue
			fi
			if [ -d "$file" ] && [ "${file::1}" != "[" ]; then
				find "$file" \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rf {} \;
				rmdir "$file" 2> /dev/null && echo "-[${file}]"
			fi
		done
		cd ..
		rmdir "$1" 2> /dev/null
	fi
}

function cleanup() {
	# cleanup target to source
	local srcPath=$1
	local tarPath=$1
	if [ "$2" != "" ]; then
		tarPath=$2
	fi

 	if [ ! -d "$srcPath" ] || [ ! -d "$tarPath" ]; then
		return 1
	fi

	cd "$tarPath"
	if [ "$(ls)" == "" ];then
		return 1
	fi
	echo "[Cleanup ${tarPath}]"
	[ "$SAY_MODE" == "ON" ] && say "정리"

	# move target to source
	local REPLSTR="-I"
	if [ "$(uname)" == "Darwin" ]; then
		REPLSTR="-J"
	fi
	find "$tarPath" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0|xargs -0 $REPLSTR % echo "[ -f \"%\" ] && mv \"%\" \"$srcPath\""|bash

	# cleanup target's sub directories
	IFS=$'\n'
	for file in $(ls -a 2> /dev/null); do
		if [ "$file" == "." ] || [ "$file" == ".." ]; then
			continue
		fi
		if [ -d "$file" ] && [ "${file::1}" != "[" ]; then
			find "$file" \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rf {} \;
			rmdir "$file" 2> /dev/null && echo "-[${file}]" || rmdirSub "$file"
		fi
	done
	IFS=$' \t\n'
}

function trimEpisodeNumberGreaterThan1000() {
	IFS=$'.'
	declare -a filename=($@)
	IFS=$' \t\n'
	if [ "${filename[1]:0:1}" == "E" ]; then
		local val=$(expr ${filename[1]:1} % 1000)
		if ((val < 10)); then
			val=0$val
		fi
		filename[1]="E$val"
		local filenameNew=""
		for n in ${!filename[@]}; do
			if (( ${#filename[@]} == n + 1 )); then
				filenameNew="$filenameNew${filename[n]}"
			else
				filenameNew="$filenameNew${filename[n]}."
			fi
		done
		echo $filenameNew
	else
		local val=$(expr ${filename[1]})
		if (( val > 170100 )); then
			local year=$(expr ${filename[1]} / 10000)
			local month=$(expr ${filename[1]} % 10000 / 100)
			local day=$(expr ${filename[1]} % 100)

			val=$(($year * 10 + $month * 31 + $day))
			if ((val < 10)); then
				val=0$val
			fi

			local filenameNew=${filename[0]}.E$val.
			for n in $(seq 2 ${#filename[@]}); do
				if (( ${#filename[@]} == n)); then
					filenameNew="$filenameNew${filename[n-1]}"
				else
					filenameNew="$filenameNew${filename[n-1]}."
				fi
			done
			echo $filenameNew
		else
			echo "$@"
		fi
	fi
	unset -v filename
}

function getTargetName() {
	local targetName="$*"
	targetName=$(echo -n "$targetName"|sed\
	-e's/[[:space:]]*\[.*\][[:space:]]*//'\
	-e's/[[:space:]]*\「.*\」[[:space:]]*//'\
	-e's/[[:space:]]*\\(.*\\)[[:space:]]*//'\
	-e's/.[0-9]*[pP]-[nN][eE][xX][tT]//'\
	-e's/.[0-9]*[pP]-[wW][iI][tT][hH]//'\
	-e's/.[0-9]*[pP]-[dD][wW][bB][hH]//'\
	-e's/.[0-9]*[pP]-[cC][iI][nN][eE][bB][uU][sS]//'\
	-e's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.m/\1.m/'\
	-e's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.a/\1.a/'\
	-e's/-[uU][nN][kK][nN][oO][wW][nN]//'\
	-e's/-[nN][uU][rR][iI]//'\
	-e's/-[mM][iI][rR][aA][cC][lL][eE]//'\
	-e's/\.[aA][aA][cC]//'\
	-e's/\.[hH][dD][tT][vV]//'\
	-e's/\.[hH]26[45]//'\
	-e's/\.[eE][nN][dD]//'\
	-e's/\.[hH][eE][vV][cC]//'\
	-e's/\.10[bB][iI][tT]//'\
	-e's/\.[xX]26[45]//'\
	-e's/\.[bB][lL][uU][rR][aA][yY]//'\
	-e's/\.[wW][eE][bB]-[dD][lL]//'\
	-e's/\.5\.1//'\
	-e's/\.[xX]26[45]//'\
	-e's/\.[bB][lL][uU][rR][aA][yY]//'\
	-e's/\.\.\./\./' -e's/\.\./\./'\
	-e's/AMZN//'\
	-e's/^[Cc]omedyTV_//'\
	-e's/^[Cc]omedy TV_//'\
	-e's/^JTBC //'\
	-e's/[0-9]부작 //'\
	-e's/추석특집 //'\
	-e's/설특집 //'\
	-e's/더 마스터-음악의 공존/더 마스터 - 음악의 공존/'\
	-e's/알\.쓸\.신\./알쓸신/'\
	-e's/일요일이 좋다 2부 런닝맨/런닝맨/'\
	-e's/TV 정보쇼/TV정보쇼/'\
	-e's/집밥 백선생 2/집밥 백선생 시즌2/'\
	-e's/효리네 민박 시즌2/효리네 민박 2/'\
	-e's/.*가요1번지/뮤직토크쇼 가요1번지/'\
	-e's/착한 마녀전 [0-9]*-[0-9]*화 합본/착한 마녀전/'\
	-e's/왕좌의 게임/Game of Thrones/'\
	-e's/Game.of.Thrones/Game of Thrones/'\
	-e's/The.Big.Bang.Theory/The Big Bang Theory/'\
	-e's/WANNA ONE GO- ZERO BASE/WANNA ONE GO - ZERO BASE/'\
	-e's/ [0-9]부\././'\
	-e's/\.[wW][eE][bB][rR][iI][pP]//'\
	-e's/\.[0-9]*[pP]//'\
	-e's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./'\
	-e's/\ E\([0-9]*\)\ /.E\1./'\
	-e's/.\([0-9]*\)\ \([0-9]*\)p/.\1.\2p/'\
	-e's/[[:space:]]*\.E/\.E/'\
	-e's/^[[:space:]]*//'\
	-e's/[[:space:]]*$//'\
	)
	targetName=$(trimEpisodeNumberGreaterThan1000 "$targetName")
    echo $targetName
}

function getTargetPathName() {
	local targetPath=$(echo "$*"|cut -d '.' -f 1)
	targetPath=$(echo $targetPath|sed\
	-e's/^[[:space:]]*//' -e's/[[:space:]]*$//'\
	-e's/[[:space:]]*스페셜$//'\
	-e's/제[0-0]*회 //'\
	-e's/ [0-9]*-[0-9]*화 합본//'\
	-e's/.*드라마 스페셜.*/KBS 드라마 스페셜/'\
	-e's/.*드라마 스테이지.*/드라마 스테이지/'\
	-e's/.*TV정보쇼.*/TV정보쇼/'\
	-e's/.*한편으로 정주행.*/몰아보기/'\
	-e's/.*의문의 일승.*/의문의 일승/'\
	-e's/.*몰아보기.*/몰아보기/'\
	-e's/.*한편으로 정주행/몰아보기/'\
	-e's/.*몰아보기/몰아보기/'\
	-e's/.*복면가왕.*/복면가왕/'\
	-e's/.*신혼일기.*/신혼일기/'\
	-e's/.*알쓸신잡.*/알쓸신잡/'\
	-e's/.*시골경찰.*/시골경찰/'\
	-e's/.*식신로드.*/식신로드/'\
	-e's/.*겟잇뷰티.*/겟잇뷰티/'\
	-e's/.*응답하라.*/응답하라/'\
	-e's/.*개밥 주는 남자.*/개밥 주는 남자/'\
	-e's/.*내 딸의 남자들.*/내 딸의 남자들/'\
	-e's/.*수업을 바꿔라.*/수업을 바꿔라/'\
	-e's/.*맛있을 지도.*/맛있을 지도/'\
	-e's/.*소사이어티 게임.*/소사이어티 게임/'\
	-e's/.*SNL 코리아.*/SNL 코리아/'\
	-e's/.*별거가 별거냐.*/별거가 별거냐/'\
	-e's/.*팬텀싱어.*/팬텀싱어/'\
	-e's/.*판타스틱 듀오.*/판타스틱 듀오/'\
	-e's/.*유닛.*/더 유닛/'\
	-e's/.*집밥 백선생.*/집밥 백선생/'\
	-e's/.*초인가족.*/초인가족/'\
	-e's/.*삼시세끼.*/삼시세끼/'\
	-e's/.*[nN][eE][wW][sS].*/뉴스/'\
	-e's/.*뉴스.*/뉴스/'\
	-e's/.*드림콘서트.*/콘서트/'\
	-e's/.*가요제.*/콘서트/'\
	-e's/.*슈퍼쇼.*/콘서트/'\
	-e's/.*시상식.*/시상식/'\
	-e's/.*컴백 스페셜.*/콘서트/'\
	-e's/.*comeback.*/콘서트/'\
	-e's/.*MAMA Red Carpet.*/시상식/'\
	-e's/.*Mnet Asian Music Awards.*/시상식/'\
	-e's/효리네 민박 2/효리네 민박 시즌2/'\
	-e's/윤식당 2/윤식당 시즌2/'\
	)
	echo $targetPath
}

function disposeMp4Catagory() {
	local srcPath=$1
	local tarPath=$1
	if [ "${2}" != "" ]; then
		tarPath=$2
	fi

 	if [ ! -d "$srcPath" ] || [ ! -d "$tarPath" ]; then
		return 1
	fi

	cd ${srcPath}
	if [ "$(ls)" == "" ];then
		return 1
	fi
	echo "[Dispose ${srcPath}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	IFS=$'\n'
	for file in $(ls *.{mp4,mkv,avi,smi,sup} 2> /dev/null); do
		local targetFile=$(getTargetName "$file")
		local targetDir="$tarPath"/$(getTargetPathName "$targetFile")
		if [ ! -d "$targetDir" ]; then
			echo "+[${targetDir}]"
			mkdir -p "$targetDir"
		fi
		[ -f "${srcPath}/$file" ] && mv -fv "${srcPath}/$file" "${targetDir}/$targetFile"
	done
	IFS=$' \t\n'
}

function cleanupRaspiDropbox() {
	#echo "[Cleanup `hostname -s`: dropbox]"
	if cleanup "$RASPI_torrentDropboxPath" "$RASPI_torrentDropboxPath"; then
		disposeMp4Catagory "$RASPI_torrentDropboxPath" "$RASPI_torrentTargetPath"
	fi
}

function disposeRaspiDropbox() {
	echo "[Dispose `hostname -s`: dropbox]"
	disposeMp4Catagory "$RASPI_torrentDropboxPath" "$RASPI_torrentTargetPath"
}

function disposeRaspiTorrent() {
	echo "[Dispose `hostname -s`: torrent]"
	case "$1" in
	c*)
		if cleanup "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"; then
			disposeMp4Catagory "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"
		fi
	;;
	*)
		disposeMp4Catagory "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"
	;;
	esac
}

function disposeMcmDropBox() {
	echo "[Dispose `hostname -s`: dropbox]"
	if cleanup "$MCM_torrentDropboxPath" "$MCM_torrentDropboxPath"; then
		disposeMp4Catagory "$MCM_torrentDropboxPath" "$MCM_torrentTargetPath"
	fi
}

function disposeMcmImac() {
	echo "[Dispose `hostname -s`]"
	case "${1}" in
	r1c*)
		if cleanup "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"; then
			disposeMp4Catagory "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"
		fi
	;;
	r1)
		disposeMp4Catagory "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"
	;;

	c*)
		if cleanup "$MCM_imacSourcePath" "$MCM_imacTargetPath"; then
			disposeMp4Catagory "$MCM_imacSourcePath" "$MCM_imacTargetPath"
		fi
	;;
	*)
		disposeMp4Catagory "$MCM_imacSourcePath" "$MCM_imacTargetPath"
	;;
	esac
}

function disposeTorrent() {
	if [ "${HOSTNAME::4}" != "iMac" ]; then
		disposeRaspiTorrent $@
		disposeRaspiDropbox
	else
		disposeMcmImac $@
		disposeMcmDropBox
	fi
}
