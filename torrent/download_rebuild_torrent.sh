#!/bin/bash

RASPI_torrentSourcePath="/mnt/rasPiTorrent/torrent"
RASPI_torrentTargetPath="/mnt/rasPiTorrent/torrent/동영상"
RASPI_torrentDropboxPath="/mnt/rasPiTorrent/torrent/떨굼상자"
MCM_torrentSourcePath="/Share/rasPiTorrent/torrent"
MCM_torrentTargetPath="/Share/rasPiTorrent/torrent/동영상"
MCM_torrentDropboxPath="/Share/rasPiTorrent/torrent/떨굼상자"

RASPI_musicSourcePath="/mnt/rasPiMusic/torrent"
RASPI_musicTargetPath="/mnt/rasPiMusic/torrent/동영상"
MCM_musicSourcePath="/Share/rasPiMusic/torrent"
MCM_musicTargetPath="/Share/rasPiMusic/torrent/동영상"

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
		exit 1
	fi

	cd "$tarPath"
	echo "[Cleanup ${tarPath}]"
	[ "$SAY_MODE" == "ON" ] && say "정리"

	# move target to source
	local REPLSTR="-I"
	if [ "$(uname)" == "Darwin" ]; then
		REPLSTR="-J"
	fi
	find "$tarPath" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 $REPLSTR % echo "[ -f \"%\" ] && mv \"%\" \"$srcPath\"" | bash

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

	echo
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
		if (( val > 180101 )); then
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
	targetName=$(echo -n "$targetName"|sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
	targetName=$(echo -n "$targetName"|sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//')
	targetName=$(echo -n "$targetName"|sed -e 's/....[pP]-[dD][wW][bB][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.m/\1.m/' -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.a/\1.a/')
	targetName=$(echo -n "$targetName"|sed -e 's/-[uU][nN][kK][nN][oO][wW][nN]//')
	targetName=$(echo -n "$targetName"|sed -e 's/-[nN][uU][rR][iI]//')
	targetName=$(echo -n "$targetName"|sed -e 's/-[mM][iI][rR][aA][cC][lL][eE]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/AMZN//')
	targetName=$(echo -n "$targetName"|sed -e 's/^[Cc]omedyTV_//' -e 's/^[Cc]omedy TV_//')
	targetName=$(echo -n "$targetName"|sed -e 's/2부작 //' -e 's/추석특집 //' -e 's/설특집 //')
	targetName=$(echo -n "$targetName"|sed -e 's/2016드라마 스페셜 /2016 드라마 스페셜 /')
	targetName=$(echo -n "$targetName"|sed -e 's/2016드라마스페셜 /2016 드라마 스페셜 /')
	targetName=$(echo -n "$targetName"|sed -e 's/2016 드라마스페셜 /2016 드라마 스페셜 /')
	targetName=$(echo -n "$targetName"|sed -e 's/2016 드라마 스페셜 - /2016 드라마 스페셜 /')
	targetName=$(echo -n "$targetName"|sed -e 's/2016 드라마 스페셜-/2016 드라마 스페셜 /')
	targetName=$(echo -n "$targetName"|sed -e 's/더 마스터-음악의 공존/더 마스터 - 음악의 공존/')
	targetName=$(echo -n "$targetName"|sed -e 's/알\.쓸\.신\./알쓸신/')
	targetName=$(echo -n "$targetName"|sed -e 's/일요일이 좋다 2부 런닝맨/런닝맨/')
	targetName=$(echo -n "$targetName"|sed -e 's/TV 정보쇼/TV정보쇼/')
	targetName=$(echo -n "$targetName"|sed -e 's/집밥 백선생 2/집밥 백선생 시즌2/')
	targetName=$(echo -n "$targetName"|sed -e 's/효리네 민박 시즌2/효리네 민박 2/')
	targetName=$(echo -n "$targetName"|sed -e 's/왕좌의 게임/Game of Thrones/')
	targetName=$(echo -n "$targetName"|sed -e 's/Game.of.Thrones/Game of Thrones/')
	targetName=$(echo -n "$targetName"|sed -e 's/WANNA ONE GO- ZERO BASE/WANNA ONE GO - ZERO BASE/')
	targetName=$(echo -n "$targetName"|sed -e 's/ .부\././' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
	targetName=$(echo -n "$targetName"|sed -e 's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./' -e 's/\ E\([0-9]*\)\ /.E\1./' -e 's/.\([0-9]*\)\ \([0-9]*\)p/.\1.\2p/')
	targetName=$(echo -n "$targetName"|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*\.E/\.E/')
    targetName=$(trimEpisodeNumberGreaterThan1000 "$targetName")
    echo $targetName
}

function getTargetPathName() {
	local targetPath=$(echo "$*" | cut -d '.' -f 1)
	targetPath=$(echo $targetPath | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*스페셜$//')
	targetPath=$(echo $targetPath | sed -e 's/제..회 //')
	targetPath=$(echo $targetPath | sed -e 's/ 미리보기//')
	targetPath=$(echo $targetPath | sed -e 's/.*드라마 스페셜.*/KBS 드라마 스페셜/')
	targetPath=$(echo $targetPath | sed -e 's/.*드라마 스테이지.*/드라마 스테이지/')
	targetPath=$(echo $targetPath | sed -e 's/.*TV정보쇼.*/TV정보쇼/')
	targetPath=$(echo $targetPath | sed -e 's/.*한편으로 정주행.*/몰아보기/')
	targetPath=$(echo $targetPath | sed -e 's/.*의문의 일승.*/의문의 일승/')
	targetPath=$(echo $targetPath | sed -e 's/.*몰아보기.*/몰아보기/')
	targetPath=$(echo $targetPath | sed -e 's/.*한편으로 정주행/몰아보기/')
	targetPath=$(echo $targetPath | sed -e 's/.*몰아보기/몰아보기/')
	targetPath=$(echo $targetPath | sed -e 's/.*복면가왕.*/복면가왕/')
	targetPath=$(echo $targetPath | sed -e 's/.*신혼일기.*/신혼일기/')
	targetPath=$(echo $targetPath | sed -e 's/.*알쓸신잡.*/알쓸신잡/')
	targetPath=$(echo $targetPath | sed -e 's/.*시골경찰.*/시골경찰/')
	targetPath=$(echo $targetPath | sed -e 's/.*식신로드.*/식신로드/')
	targetPath=$(echo $targetPath | sed -e 's/.*겟잇뷰티.*/겟잇뷰티/')
	targetPath=$(echo $targetPath | sed -e 's/.*응답하라.*/응답하라/')
	targetPath=$(echo $targetPath | sed -e 's/.*개밥 주는 남자.*/개밥 주는 남자/')
	targetPath=$(echo $targetPath | sed -e 's/.*내 딸의 남자들.*/내 딸의 남자들/')
	targetPath=$(echo $targetPath | sed -e 's/.*수업을 바꿔라.*/수업을 바꿔라/')
	targetPath=$(echo $targetPath | sed -e 's/.*맛있을 지도.*/맛있을 지도/')
	targetPath=$(echo $targetPath | sed -e 's/.*소사이어티 게임.*/소사이어티 게임/')
	targetPath=$(echo $targetPath | sed -e 's/.*SNL 코리아.*/SNL 코리아/')
	targetPath=$(echo $targetPath | sed -e 's/.*별거가 별거냐.*/별거가 별거냐/')
	targetPath=$(echo $targetPath | sed -e 's/.*팬텀싱어.*/팬텀싱어/')
	targetPath=$(echo $targetPath | sed -e 's/.*판타스틱 듀오.*/판타스틱 듀오/')
	targetPath=$(echo $targetPath | sed -e 's/.*유닛.*/더 유닛/')
	targetPath=$(echo $targetPath | sed -e 's/.*집밥 백선생.*/집밥 백선생/')
	targetPath=$(echo $targetPath | sed -e 's/.*초인가족.*/초인가족/')
	targetPath=$(echo $targetPath | sed -e 's/.*삼시세끼.*/삼시세끼/')
	targetPath=$(echo $targetPath | sed -e 's/.*[nN][eE][wW][sS].*/뉴스/')
	targetPath=$(echo $targetPath | sed -e 's/.*뉴스.*/뉴스/')
	targetPath=$(echo $targetPath | sed -e 's/.*드림콘서트.*/콘서트/')
	targetPath=$(echo $targetPath | sed -e 's/.*가요제.*/콘서트/')
	targetPath=$(echo $targetPath | sed -e 's/.*슈퍼쇼.*/콘서트/')
	targetPath=$(echo $targetPath | sed -e 's/.*컴백 스페셜.*/콘서트/')
	targetPath=$(echo $targetPath | sed -e 's/.*comeback.*/콘서트/')
	targetPath=$(echo $targetPath | sed -e 's/.*MAMA Red Carpet.*/시상식/')
	targetPath=$(echo $targetPath | sed -e 's/.*Mnet Asian Music Awards.*/시상식/')
	targetPath=$(echo $targetPath | sed -e 's/.*시상식.*/시상식/')
	echo $targetPath
}

function rebuildMp4Catagory() {
	local srcPath=$1
	local tarPath=$1
	if [ "${2}" != "" ]; then
		tarPath=$2
	fi

 	if [ ! -d "$srcPath" ] || [ ! -d "$tarPath" ]; then
		exit 1
	fi

	cd ${srcPath}
	echo "[Rebuild ${srcPath}]"
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

	echo
}

function rebuildRaspiMusic() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	c*)
		cleanup ${RASPI_musicSourcePath} ${RASPI_musicTargetPath}
		rebuildMp4Catagory ${RASPI_musicSourcePath} ${RASPI_musicTargetPath}
	;;
	*)
		rebuildMp4Catagory ${RASPI_musicSourcePath} ${RASPI_musicTargetPath}
	;;
	esac
}

function cleanupRaspiDropbox() {
	echo "[Cleanup `hostname -s`: dropbox]"
	cleanup "$RASPI_torrentDropboxPath" "$RASPI_torrentDropboxPath"
}

function rebuildRaspiDropbox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	rebuildMp4Catagory "$RASPI_torrentDropboxPath" "$RASPI_torrentTargetPath"
}

function rebuildRaspiTorrent() {
	echo "[Rebuild `hostname -s`: torrent]"
	case "$1" in
	c*)
		cleanup "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"
		rebuildMp4Catagory "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"
	;;
	*)
		rebuildMp4Catagory "$RASPI_torrentSourcePath" "$RASPI_torrentTargetPath"
	;;
	esac
}

function rebuildMcmDropBox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	cleanup "$MCM_torrentDropboxPath" "$MCM_torrentDropboxPath"
	rebuildMp4Catagory "$MCM_torrentDropboxPath" "$MCM_torrentTargetPath"
}

function rebuildMcmImac() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	r1c*)
		cleanup "$MCM_musicSourcePath" "$MCM_musicTargetPath"
		rebuildMp4Catagory "$MCM_musicSourcePath" "$MCM_musicTargetPath"

		cleanup "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"
		rebuildMp4Catagory "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"
	;;
	r1)
		rebuildMp4Catagory "$MCM_musicSourcePath" "$MCM_musicTargetPath"
		rebuildMp4Catagory "$MCM_torrentSourcePath" "$MCM_torrentTargetPath"
	;;

	c*)
		cleanup "$MCM_imacSourcePath" "$MCM_imacTargetPath"
		rebuildMp4Catagory "$MCM_imacSourcePath" "$MCM_imacTargetPath"
	;;
	*)
		rebuildMp4Catagory "$MCM_imacSourcePath" "$MCM_imacTargetPath"
	;;
	esac
}

function rebuildTorrent() {
	if [ "${HOSTNAME::4}" != "iMac" ]; then
		#[ "$(basename $0 | cut -d_ -f 1)" == "local" ] && rebuildRaspiMusic $@ || rebuildRaspiTorrent $@
		#rebuildRaspiMusic $@
		rebuildRaspiTorrent $@
		rebuildRaspiDropbox
	else
		rebuildMcmImac $@
		rebuildMcmDropBox
	fi
}
