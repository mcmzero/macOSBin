#!/bin/bash

function cleanup() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi

	cd ${TRG_DIR}
	echo Cleanup ${TRG_DIR}
	for FILE in *; do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" == "[" ]; then
			echo Pass: ${FILE}
		else
			echo find "${FILE}" -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" -exec mv -v '{}' ${SRC_DIR} \;
			find "${FILE}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -exec mv -v '{}' ${SRC_DIR} \;
		fi
	done

	for FILE in *; do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" != "[" ]; then
			find "${FILE}" -name ".DS_Store" -exec rm '{}' \;
			rmdir "${FILE}" 2> /dev/null && echo rmdir "${FILE}"
		fi
	done
}

function rebuild_mp4_catagory() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi
	echo "src: $SRC_DIR tar: $TRG_DIR"

	if [ "${SRC_DIR}" != "${TRG_DIR}" ]; then
		echo Prepair ${SRC_DIR}
		echo find "${SRC_DIR}" -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" -exec mv -v '{}' "${TRG_DIR}" \;
		find "${SRC_DIR}" \( -name "*.mp4" -or -name "*.mkv" -or -name "*.avi" -or -name "*.smi" -or -name "*.sup" \) -exec mv -v '{}' "${TRG_DIR}" \;
		echo mv ${TRG_DIR}/*.{mp4,mkv,avi,smi,sup} ${SRC_DIR}
		mv ${TRG_DIR}/*.{mp4,mkv,avi,smi,sup} ${SRC_DIR}
		echo
	fi

	cd ${SRC_DIR}
	echo Rebuild ${SRC_DIR}
	for FILE in *.{mp4,mkv,avi,smi,sup}; do
		if [ "${FILE}" != "*.mp4" ] && [ "${FILE}" != "*.mkv" ] && [ "${FILE}" != "*.avi" ] && [ "${FILE}" != "*.smi" ] && [ "${FILE}" != "*.sup" ]; then
			TARGET_NAME=$(echo -n ${FILE} | sed -e 's/[[:space:]]*\[.*\][[:space:]]*//' -e 's/[[:space:]]*\「.*\」[[:space:]]*//' -e 's/[[:space:]]*\\(.*\\)[[:space:]]*//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/....[pP]-[nN][eE][xX][tT]//' -e 's/....[pP]-[wW][iI][tT][hH]//' -e 's/....[pP]-[cC][iI][nN][eE][bB][uU][sS]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/\.[aA][aA][cC]//' -e 's/\.[hH][dD][tT][vV]//' -e 's/\.[hH]26[45]//' -e 's/\.[eE][nN][dD]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/\.[hH][eE][vV][cC]//' -e 's/\.10[bB][iI][tT]//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/\.[wW][eE][bB]-[dD][lL]//' -e 's/-.*\././' -e 's/\.5\.1//' -e 's/\.[xX]26[45]//' -e 's/\.[bB][lL][uU][rR][aA][yY]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/\.\.\./\./' -e 's/\.\./\./' -e 's/알\.쓸\.신\./알쓸신/' -e 's/AMZN//' -e 's/Game.of.Thrones/Game of Thrones/')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/ .부\.//' -e 's/\.[wW][eE][bB][rR][iI][pP]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/\.1440[pP]//' -e 's/\.1080[pP]//' -e 's/\.720[pP]//' -e 's/\.360[pP]//')
			TARGET_NAME=$(echo -n "${TARGET_NAME}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
			DIR_NAME=${TRG_DIR}/$(echo $TARGET_NAME | cut -d . -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
			if [ ! -d "${DIR_NAME}" ]; then
				echo mkdir -pv "${DIR_NAME}"
				mkdir -pv "${DIR_NAME}"
			fi
			mv -fv "${SRC_DIR}/${FILE}" "${DIR_NAME}/${TARGET_NAME}"
		fi
	done
}

function rebuild_raspberryPi() {
	echo "Rebuild ROUTER TORRENT"
	SOURCE_DIR=/media/torrent
	case "${1}" in
	r*)
		cleanup ${SOURCE_DIR}
		rebuild_mp4_catagory ${SOURCE_DIR}
	;;
	*)
		rebuild_mp4_catagory ${SOURCE_DIR}
	;;
	esac
}

function rebuild_changmin() {
	echo "Rebuild CHANGMIN"
	TORRENT_DIR=/Share/torrent
	SOURCE_DIR=/Volumes/Movies/Torrent
	TARGET_DIR=/Volumes/Movies/TV
	case "${1}" in
	ct*)
			cleanup ${TORRENT_DIR}
			rebuild_mp4_catagory ${TORRENT_DIR}
	;;
	t*)
			rebuild_mp4_catagory ${TORRENT_DIR}
	;;
	cleanup)
			cleanup ${SOURCE_DIR} ${TARGET_DIR}
			rebuild_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
	;;
	*)
			rebuild_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
	;;
	esac
}

HOSTNAME=$(hostname | cut -c 1-4)
if [ "${HOSTNAME}" == "rasp" ]; then
	rebuild_raspberryPi $@
else
	rebuild_changmin $@
fi
