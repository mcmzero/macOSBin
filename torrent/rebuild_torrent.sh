#!/bin/bash

[ "$(hostname -s |cut -c 1-4)" == "iMac" ] && SAY_MODE=ON

function cleanup() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi

	cd ${TRG_DIR}
	echo "[Cleanup ${TRG_DIR}]"
	[ "${SAY_MODE}" == "ON" ] && say "정리"

	for FILE in *; do
		if [ "$(echo ${FILE} | cut -c 1)" == "[" ]; then
			mv "${FILE}" ".${FILE}" 2> /dev/null
		fi
	done

	find "${TRG_DIR}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -I % mv % ${SRC_DIR} 2> /dev/null

	for FILE in *; do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" != "[" ]; then
			find "${FILE}" -name ".DS_Store" -delete
			rmdir "${FILE}" 2> /dev/null && echo "-[${FILE}]"
		fi
	done

	for FILE in .*; do
        if [ "$(echo ${FILE} | cut -c 1-2)" == ".[" ]; then
			mv "${FILE}" "$(echo $FILE | sed -e 's/^.\[/\[/')" 2> /dev/null
        fi
	done
	echo
}

function get_target_name() {
	GET_TARGET_NAME=$(echo -n ${@} | sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/-.*\././' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/알\.쓸\.신\./알쓸신/' -e 's/AMZN//' -e 's/Game.of.Thrones/Game of Thrones/')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/ .부\././' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
	GET_TARGET_NAME=$(echo -n "${GET_TARGET_NAME}" | sed -e 's/\(^[0-9]*\)\.\([^\.]*\.\)/\2\1./')
	echo -n "${GET_TARGET_NAME}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function get_target_dir_name() {
	echo $@ | cut -d . -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function rebuild_mp4_catagory() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi

	if [ "${SRC_DIR}" != "${TRG_DIR}" ]; then
		echo "[Prepair ${SRC_DIR}]"
		[ "${SAY_MODE}" == "ON" ] && say "준비"
		find "${SRC_DIR}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -I % mv % "${TRG_DIR}" 2> /dev/null
		echo "[${TRG_DIR}/*.{mp4,mkv,avi,smi,sup}] -> [${SRC_DIR}]"
		mv ${TRG_DIR}/*.{mp4,mkv,avi,smi,sup} ${SRC_DIR} 2> /dev/null
		echo
	fi

	cd ${SRC_DIR}
	echo "[Rebuild ${SRC_DIR}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	for FILE in *.{mp4,mkv,avi,smi,sup}; do
		if [ "${FILE}" != "*.mp4" ] && [ "${FILE}" != "*.mkv" ] && [ "${FILE}" != "*.avi" ] && [ "${FILE}" != "*.smi" ] && [ "${FILE}" != "*.sup" ]; then
			TARGET_NAME=$(get_target_name "$FILE")
			DIR_NAME=${TRG_DIR}/$(get_target_dir_name "$TARGET_NAME")
			if [ ! -d "${DIR_NAME}" ]; then
				echo "+[${DIR_NAME}]"
				mkdir -p "${DIR_NAME}"
			fi
			mv "${SRC_DIR}/${FILE}" "${DIR_NAME}/${TARGET_NAME}" 2> /dev/null
		fi
	done
	echo
}

function rebuild_raspberryPi() {
	echo "[Rebuild `hostname -s`]"
	SOURCE_DIR=/media/torrent
	case "${1}" in
	cleanup)
		cleanup ${SOURCE_DIR}
		rebuild_mp4_catagory ${SOURCE_DIR}
	;;
	*)
		rebuild_mp4_catagory ${SOURCE_DIR}
	;;
	esac
}

function rebuild_changmin() {
	echo "[Rebuild `hostname -s`]"
	TORRENT_DIR=/Share/nas
	SOURCE_DIR=/Volumes/Movies
	TARGET_DIR=/Volumes/Movies/TV
	case "${1}" in
	r1c*)
			cleanup ${TORRENT_DIR}
			rebuild_mp4_catagory ${TORRENT_DIR}
	;;
	r1)
			rebuild_mp4_catagory ${TORRENT_DIR}
	;;
	c*)
			cleanup ${SOURCE_DIR} ${TARGET_DIR}
			rebuild_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
	;;
	*)
			rebuild_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
	;;
	esac
}

HOSTNAME=$(hostname -s | cut -c 1-4)
if [ "${HOSTNAME}" == "rasp" ]; then
	rebuild_raspberryPi $@
else
	rebuild_changmin $@
fi
