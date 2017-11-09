#!/bin/bash

RAS_SOURCE_PATH=/media/torrent
RAS_TARGET_PATH=/media/torrent/동영상

TORRENT_SOURCE_PATH=/Share/nas
TORRENT_TARGET_PATH=/Share/nas/동영상

MCM_SOURCE_PATH=/Volumes/Movies
MCM_TARGET_PATH=/Volumes/Movies

[ "$(hostname -s |cut -c 1-4)" == "iMac" ] && SAY_MODE=ON

function cleanup() {
	SRC_PATH=$1
	if [ "${2}" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	cd ${TAR_PATH}
	echo "[Cleanup ${TAR_PATH}]"
	[ "${SAY_MODE}" == "ON" ] && say "정리"

	if [ "$(uname)" == "Darwin" ]; then
		find "${TAR_PATH}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -J % mv % ${SRC_PATH}
	else
		find "${TAR_PATH}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -print0 | xargs -0 -I % mv % ${SRC_PATH}
	fi

	for FILE in *; do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" != "[" ]; then
			find "${FILE}" -name ".DS_Store" -delete
			rmdir "${FILE}" 2> /dev/null && echo "-[${FILE}]"
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

function get_target_PATH_name() {
	echo $@ | cut -d . -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function rebuild_mp4_catagory() {
	SRC_PATH=$1
	if [ "${2}" != "" ]; then
		TAR_PATH=$2
	else
		TAR_PATH=$1
	fi

	cd ${SRC_PATH}
	echo "[Rebuild ${SRC_PATH}]"
	[ "${SAY_MODE}" == "ON" ] && say "재생성"

	for FILE in *.{mp4,mkv,avi,smi,sup}; do
		if [ "${FILE}" != "*.mp4" ] && [ "${FILE}" != "*.mkv" ] && [ "${FILE}" != "*.avi" ] && [ "${FILE}" != "*.smi" ] && [ "${FILE}" != "*.sup" ]; then
			TARGET_NAME=$(get_target_name "$FILE")
			DIR_NAME=${TAR_PATH}/$(get_target_PATH_name "$TARGET_NAME")
			if [ ! -d "${DIR_NAME}" ]; then
				echo "+[${DIR_NAME}]"
				mkdir -p "${DIR_NAME}"
			fi
			mv "${SRC_PATH}/${FILE}" "${DIR_NAME}/${TARGET_NAME}" 2> /dev/null
		fi
	done
	echo
}

function rebuild_raspberryPi() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	c*)
		cleanup ${RAS_SOURCE_PATH} ${RAS_TARGET_PATH}
		rebuild_mp4_catagory ${RAS_SOURCE_PATH} ${RAS_TARGET_PATH}
	;;
	*)
		rebuild_mp4_catagory ${RAS_SOURCE_PATH} ${RAS_TARGET_PATH}
	;;
	esac
}

function rebuild_changmin() {
	echo "[Rebuild `hostname -s`]"
	case "${1}" in
	r1c*)
			cleanup ${TORRENT_SOURCE_PATH} ${TORRENT_TARGET_PATH}
			rebuild_mp4_catagory ${TORRENT_SOURCE_PATH} ${TORRENT_TARGET_PATH}
	;;
	r1)
			rebuild_mp4_catagory ${TORRENT_SOURCE_PATH} ${TORRENT_TARGET_PATH}
	;;
	c*)
			cleanup ${MCM_SOURCE_PATH} ${MCM_TARGET_PATH}
			rebuild_mp4_catagory ${MCM_SOURCE_PATH} ${MCM_TARGET_PATH}
	;;
	*)
			rebuild_mp4_catagory ${MCM_SOURCE_PATH} ${MCM_TARGET_PATH}
	;;
	esac
}

HOSTNAME=$(hostname -s | cut -c 1-4)
if [ "${HOSTNAME}" == "rasp" ]; then
	rebuild_raspberryPi $@
else
	rebuild_changmin $@
fi
