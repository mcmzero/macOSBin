#!/bin/bash

RASPI_TORRENT_SOURCE_PATH="/mnt/rasPiTorrent/torrent"
RASPI_TORRENT_TARGET_PATH="/mnt/rasPiTorrent/torrent/동영상"
RASPI_TORRENT_DROPBOX_PATH="/mnt/rasPiTorrent/torrent/떨굼상자"
MCM_TORRENT_SOURCE_PATH="/Share/rasPiTorrent/torrent"
MCM_TORRENT_TARGET_PATH="/Share/rasPiTorrent/torrent/동영상"
MCM_TORRENT_DROPBOX_PATH="/Share/rasPiTorrent/torrent/떨굼상자"

RASPI_MUSIC_SOURCE_PATH="/mnt/rasPiMusic/torrent"
RASPI_MUSIC_TARGET_PATH="/mnt/rasPiMusic/torrent/동영상"
MCM_MUSIC_SOURCE_PATH="/Share/rasPiMusic/torrent"
MCM_MUSIC_TARGET_PATH="/Share/rasPiMusic/torrent/동영상"

MCM_IMAC_SOURCE_PATH="$HOME/Downloads"
MCM_IMAC_TARGET_PATH="$HOME/Downloads"

[ "${HOSTNAME::4}" == "iMac" ] && SAY_MODE=ON

function rmdir_sub() {
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
	local SRC_PATH=$1
	local TAR_PATH=$1
	if [ "$2" != "" ]; then
		TAR_PATH=$2
	fi

	[ -d "$SRC_PATH" ] || exit
	[ -d "$TAR_PATH" ] || exit

	cd "$TAR_PATH"
	echo "[Cleanup ${TAR_PATH}]"
	[ "$SAY_MODE" == "ON" ] && say "정리"

	# move target to source
	local REPLSTR="-I"
	if [ "$(uname)" == "Darwin" ]; then
		REPLSTR="-J"
	fi
	find "$TAR_PATH" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 $REPLSTR % echo "[ -f \"%\" ] && mv \"%\" \"$SRC_PATH\"" | bash

	# cleanup target's sub directories
	IFS=$'\n'
	for file in $(ls -a 2> /dev/null); do
		if [ "$file" == "." ] || [ "$file" == ".." ]; then
			continue
		fi
		if [ -d "$file" ] && [ "${file::1}" != "[" ]; then
			find "$file" \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rf {} \;
			rmdir "$file" 2> /dev/null && echo "-[${file}]" || rmdir_sub "$file"
		fi
	done
	IFS=$' \t\n'

	echo
}

function trim_episode_number_greater_than_1000() {
	IFS=$'.'
	declare -a filename=($@)
	IFS=$' \t\n'
	if [ "${filename[1]:0:1}" == "E" ]; then
		local val=$(expr ${filename[1]:1} % 1000)
		if ((val < 10)); then
			val=0$val
		fi
		filename[1]="E$val"
		local filename_new=""
		for n in ${!filename[@]}; do
			if (( ${#filename[@]} == n + 1 )); then
				filename_new="$filename_new${filename[n]}"
			else
				filename_new="$filename_new${filename[n]}."
			fi
		done
		echo $filename_new
    else
        echo "$@"
    fi

	unset -v filename
}

function get_target_name() {
	local target_name="$*"
	target_name=$(echo -n "$target_name"|sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
	target_name=$(echo -n "$target_name"|sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
	target_name=$(echo -n "$target_name"|sed -e 's/....[pP]-[dD][wW][bB][hH]//' -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.m/\1.m/' -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.a/\1.a/')
	target_name=$(echo -n "$target_name"|sed -e 's/-[uU][nN][kK][nN][oO][wW][nN]//')
	target_name=$(echo -n "$target_name"|sed -e 's/-[nN][uU][rR][iI]//')
	target_name=$(echo -n "$target_name"|sed -e 's/-[mM][iI][rR][aA][cC][lL][eE]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/AMZN//')
	target_name=$(echo -n "$target_name"|sed -e 's/^[Cc]omedyTV_//' -e 's/^[Cc]omedy TV_//')
	target_name=$(echo -n "$target_name"|sed -e 's/2부작 //' -e 's/추석특집 //' -e 's/설특집 //')

	target_name=$(echo -n "$target_name"|sed -e 's/2016드라마 스페셜 /2016 드라마 스페셜 /')
	target_name=$(echo -n "$target_name"|sed -e 's/2016드라마스페셜 /2016 드라마 스페셜 /')
	target_name=$(echo -n "$target_name"|sed -e 's/2016 드라마스페셜 /2016 드라마 스페셜 /')
	target_name=$(echo -n "$target_name"|sed -e 's/2016 드라마 스페셜 - /2016 드라마 스페셜 /')
	target_name=$(echo -n "$target_name"|sed -e 's/2016 드라마 스페셜-/2016 드라마 스페셜 /')
	target_name=$(echo -n "$target_name"|sed -e 's/더 마스터-음악의 공존/더 마스터 - 음악의 공존/')
	target_name=$(echo -n "$target_name"|sed -e 's/알\.쓸\.신\./알쓸신/')
	target_name=$(echo -n "$target_name"|sed -e 's/일요일이 좋다 2부 런닝맨/런닝맨/')
	target_name=$(echo -n "$target_name"|sed -e 's/TV 정보쇼/TV정보쇼/')
	target_name=$(echo -n "$target_name"|sed -e 's/집밥 백선생 2/집밥 백선생 시즌2/')
	target_name=$(echo -n "$target_name"|sed -e 's/효리네 민박 시즌2/효리네 민박 2/')

	target_name=$(echo -n "$target_name"|sed -e 's/왕좌의 게임/Game of Thrones/')
	target_name=$(echo -n "$target_name"|sed -e 's/Game.of.Thrones/Game of Thrones/')
	target_name=$(echo -n "$target_name"|sed -e 's/WANNA ONE GO- ZERO BASE/WANNA ONE GO - ZERO BASE/')

	target_name=$(echo -n "$target_name"|sed -e 's/ .부\././' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
	target_name=$(echo -n "$target_name"|sed -e 's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./' -e 's/\ E\([0-9]*\)\ /.E\1./' -e 's/.\([0-9]*\)\ \([0-9]*\)p/.\1.\2p/')

	#trim space
	target_name=$(echo -n "$target_name"|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*\.E/\.E/')

    target_name=$(trim_episode_number_greater_than_1000 "$target_name")
    echo $target_name
}

function get_target_path_name() {
	TARGET_PATH_NAME=$(echo "$*" | cut -d '.' -f 1)
	#trim space
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*스페셜$//')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/제..회 //')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/ 미리보기//')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*드라마 스페셜.*/KBS 드라마 스페셜/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*드라마 스테이지.*/드라마 스테이지/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*TV정보쇼.*/TV정보쇼/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*한편으로 정주행.*/몰아보기/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*의문의 일승.*/의문의 일승/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*몰아보기.*/몰아보기/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*한편으로 정주행/몰아보기/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*몰아보기/몰아보기/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*복면가왕.*/복면가왕/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*신혼일기.*/신혼일기/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*알쓸신잡.*/알쓸신잡/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*시골경찰.*/시골경찰/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*식신로드.*/식신로드/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*겟잇뷰티.*/겟잇뷰티/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*응답하라.*/응답하라/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*개밥 주는 남자.*/개밥 주는 남자/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*내 딸의 남자들.*/내 딸의 남자들/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*수업을 바꿔라.*/수업을 바꿔라/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*맛있을 지도.*/맛있을 지도/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*소사이어티 게임.*/소사이어티 게임/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*SNL 코리아.*/SNL 코리아/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*별거가 별거냐.*/별거가 별거냐/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*팬텀싱어.*/팬텀싱어/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*판타스틱 듀오.*/판타스틱 듀오/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*유닛.*/더 유닛/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*집밥 백선생.*/집밥 백선생/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*초인가족.*/초인가족/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*삼시세끼.*/삼시세끼/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*[nN][eE][wW][sS].*/뉴스/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*뉴스.*/뉴스/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*드림콘서트.*/콘서트/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*가요제.*/콘서트/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*슈퍼쇼.*/콘서트/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*컴백 스페셜.*/콘서트/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*comeback.*/콘서트/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*MAMA Red Carpet.*/시상식/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*Mnet Asian Music Awards.*/시상식/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*시상식.*/시상식/')
	echo ${TARGET_PATH_NAME}
}

function rebuild_mp4_catagory() {
	local SRC_PATH=$1
	local TAR_PATH=$1
	if [ "${2}" != "" ]; then
		TAR_PATH=$2
	fi

	[ -d "$SRC_PATH" ] || exit
	[ -d "$TAR_PATH" ] || exit

	cd ${SRC_PATH}
	echo "[Rebuild ${SRC_PATH}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	IFS=$'\n'
	for file in $(ls *.{mp4,mkv,avi,smi,sup} 2> /dev/null); do
		local target_file=$(get_target_name "$file")
		local target_dir="$TAR_PATH"/$(get_target_path_name "$target_file")
		if [ ! -d "$target_dir" ]; then
			echo "+[${target_dir}]"
			mkdir -p "$target_dir"
		fi
		[ -f "${SRC_PATH}/$file" ] && mv -fv "${SRC_PATH}/$file" "${target_dir}/$target_file"
	done
	IFS=$' \t\n'

	echo
}

function rebuild_raspi_music() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	c*)
		cleanup ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
		rebuild_mp4_catagory ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
	;;
	*)
		rebuild_mp4_catagory ${RASPI_MUSIC_SOURCE_PATH} ${RASPI_MUSIC_TARGET_PATH}
	;;
	esac
}

function cleanup_raspi_dropbox() {
	echo "[Cleanup `hostname -s`: dropbox]"
	cleanup "$RASPI_TORRENT_DROPBOX_PATH" "$RASPI_TORRENT_DROBOX_PATH"
}

function rebuild_raspi_dropbox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	rebuild_mp4_catagory "$RASPI_TORRENT_DROPBOX_PATH" "$RASPI_TORRENT_TARGET_PATH"
}

function rebuild_raspi_torrent() {
	echo "[Rebuild `hostname -s`: torrent]"
	case "$1" in
	c*)
		cleanup "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
		rebuild_mp4_catagory "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
	;;
	*)
		rebuild_mp4_catagory "$RASPI_TORRENT_SOURCE_PATH" "$RASPI_TORRENT_TARGET_PATH"
	;;
	esac
}

function rebuild_mcm_dropbox() {
	echo "[Rebuild `hostname -s`: dropbox]"
	cleanup "$MCM_TORRENT_DROPBOX_PATH" "$MCM_TORRENT_DROBOX_PATH"
	rebuild_mp4_catagory "$MCM_TORRENT_DROPBOX_PATH" "$MCM_TORRENT_TARGET_PATH"
}

function rebuild_mcm_imac() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	r1c*)
			cleanup "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"

			cleanup "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
	;;
	r1)
			rebuild_mp4_catagory "$MCM_MUSIC_SOURCE_PATH" "$MCM_MUSIC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_TORRENT_SOURCE_PATH" "$MCM_TORRENT_TARGET_PATH"
	;;

	c*)
			cleanup "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
			rebuild_mp4_catagory "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
	;;
	*)
			rebuild_mp4_catagory "$MCM_IMAC_SOURCE_PATH" "$MCM_IMAC_TARGET_PATH"
	;;
	esac
}

function rebuild_torrent() {
	if [ "${HOSTNAME::4}" != "iMac" ]; then
		#[ "$(basename $0 | cut -d_ -f 1)" == "local" ] && rebuild_raspi_music $@ || rebuild_raspi_torrent $@
		#rebuild_raspi_music $@
		rebuild_raspi_torrent $@
		rebuild_raspi_dropbox
	else
		rebuild_mcm_imac $@
		rebuild_mcm_dropbox
	fi
}
