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

[ "$(hostname -s |cut -c 1-4)" == "iMac" ] && SAY_MODE=ON

function rmdir_sub() {
	if [ -d "$1" ]; then
		cd "$1"
		for FILE in *; do
			if [ -d "$FILE" ] && [ "$(echo ${FILE}|cut -c 1)" != "[" ]; then
				#find "$FILE" \( -name ".DS_Store" -or -name ".Parent" -or -name ".AppleDouble" \) -delete
				find "$FILE" \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rf {} \;
				rmdir "$FILE" 2> /dev/null && echo "-[${FILE}]"
			fi
		done
		cd ..
		rmdir "$1" 2> /dev/null
	fi
}

function mv_file() {
	[ -f "$1" ] && mv "$1" "$2"
}

function cleanup() {
	# cleanup target to source
	SRC_PATH=$1
	if [ "$2" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	[ -d "$SRC_PATH" ] || exit
	[ -d "$TAR_PATH" ] || exit

	cd "$TAR_PATH"
	echo "[Cleanup ${TAR_PATH}]"
	[ "$SAY_MODE" == "ON" ] && say "정리"

	# move target to source
	if [ "$(uname)" == "Darwin" ]; then
		find "$TAR_PATH" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -J % echo "[ -f \"%\" ] && mv \"%\" \"$SRC_PATH\"" | bash
	else
		find "$TAR_PATH" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -I % echo "[ -f \"%\" ] && mv \"%\" \"$SRC_PATH\"" | bash
	fi

	# cleanup target's sub directories
	for FILE in *; do
		if [ -d "$FILE" ] && [ "$(echo ${FILE}|cut -c 1)" != "[" ]; then
			#find "$FILE" \( -name ".DS_Store" -or -name ".Parent" -or -name ".AppleDouble" \) -delete
			find "$FILE" \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rf {} \;
			rmdir "$FILE" 2> /dev/null && echo "-[${FILE}]" || rmdir_sub "$FILE"
		fi
	done

	echo
}

function get_target_name() {
	GET_TARGET_NAME=$(echo -n "$@"|sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/....[pP]-[dD][wW][bB][hH]//' -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.m/\1.m/' -e 's/\([0-9][0-9][0-9][0-9][0-9][0-9]\)-.*.a/\1.a/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/AMZN//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/^[Cc]omedyTV_//' -e 's/^[Cc]omedy TV_//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2부작 //' -e 's/추석특집 //' -e 's/설특집 //')

	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2016드라마 스페셜 /2016 드라마 스페셜 /')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2016드라마스페셜 /2016 드라마 스페셜 /')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2016 드라마스페셜 /2016 드라마 스페셜 /')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2016 드라마 스페셜 - /2016 드라마 스페셜 /')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/2016 드라마 스페셜-/2016 드라마 스페셜 /')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/더 마스터-음악의 공존/더 마스터 - 음악의 공존/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/알\.쓸\.신\./알쓸신/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/일요일이 좋다 2부 런닝맨/런닝맨/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/TV 정보쇼/TV정보쇼/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/집밥 백선생 2/집밥 백선생 시즌2/')

	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/왕좌의 게임/Game of Thrones/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/Game.of.Thrones/Game of Thrones/')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/WANNA ONE GO- ZERO BASE/WANNA ONE GO - ZERO BASE/')

	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/ .부\././' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
	GET_TARGET_NAME=$(echo -n "$GET_TARGET_NAME"|sed -e 's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./' -e 's/\ E\([0-9]*\)\ /.E\1./' -e 's/.\([0-9]*\)\ \([0-9]*\)p/.\1.\2p/')
	#GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/-.*\././')
	echo -n "$GET_TARGET_NAME"|sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*\.E/\.E/'
}

function get_target_path_name() {
	TARGET_PATH_NAME=$(echo "$*" | cut -d . -f 1)
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]*스페셜$//')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/제..회 //')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/ 미리보기//')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*드라마 스페셜.*/KBS 드라마 스페셜/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*TV정보쇼.*/TV정보쇼/')
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*정글의 법칙.*/정글의 법칙/')
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
	TARGET_PATH_NAME=$(echo $TARGET_PATH_NAME | sed -e 's/.*윤식당.*/윤식당/')
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
	SRC_PATH=$1
	if [ "${2}" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	[ -d "$SRC_PATH" ] || exit
	[ -d "$TAR_PATH" ] || exit

	cd ${SRC_PATH}
	echo "[Rebuild ${SRC_PATH}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	for FILE in *.{mp4,mkv,avi,smi,sup}; do
		if [ -f "$FILE" ] && [ "$FILE" != "*.mp4" ] && [ "$FILE" != "*.mkv" ] && [ "$FILE" != "*.avi" ] && [ "$FILE" != "*.smi" ] && [ "$FILE" != "*.sup" ]; then
			TARGET_NAME=$(get_target_name "$FILE")
			DIR_NAME="$TAR_PATH"/$(get_target_path_name "$TARGET_NAME")
			if [ ! -d "$DIR_NAME" ]; then
				echo "+[${DIR_NAME}]"
				mkdir -p "$DIR_NAME"
			fi
			#mv "${SRC_PATH}/$FILE" "${DIR_NAME}/$TARGET_NAME" 2> /dev/null
			[ -f "${SRC_PATH}/$FILE" ] && mv -fv "${SRC_PATH}/$FILE" "${DIR_NAME}/$TARGET_NAME"
		fi
	done
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
	HOSTNAME=$(hostname -s | cut -c 1-4)
	#echo $HOSTNAME
	if [ "${HOSTNAME}" != "iMac" ]; then
		#[ "$(basename $0 | cut -d_ -f 1)" == "local" ] && rebuild_raspi_music $@ || rebuild_raspi_torrent $@
		#rebuild_raspi_music $@
		rebuild_raspi_torrent $@
		rebuild_raspi_dropbox
	else
		rebuild_mcm_imac $@
		rebuild_mcm_dropbox
	fi
}
