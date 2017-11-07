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
	for FILE in *
	do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" == "[" ]; then
			echo Pass: ${FILE}
		else
			find ${TRG_DIR}/${FILE} -name *.mp4 -exec mv -v '{}' ${SRC_DIR} \;
		fi
	done

	for FILE in *
	do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" != "[" ]; then
			find ${TRG_DIR}/${FILE} -name .DS_Store -exec rm '{}' \;
			rmdir ${FILE} 2> /dev/null && echo rmdir ${FILE}
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
		echo find "${SRC_DIR}" -name *.mp4 -exec mv -v '{}' "${TRG_DIR}" \;
		find "${SRC_DIR}" -name *.mp4 -exec mv -v '{}' "${TRG_DIR}" \;
		echo mv -v "${TRG_DIR}"/*.mp4 "${SRC_DIR}"
		mv -v "${TRG_DIR}"/*.mp4 "${SRC_DIR}"
	fi

	cd ${SRC_DIR}
	echo Rebuild ${SRC_DIR}
	for FILE in *.mp4
	do
		if [ "${FILE}" != "*.mp4" ]; then
			TARGET_NAME=$(echo $FILE | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/....p-NEXT//' -e 's/\.\./\./' -e 's/\.END//' -e 's/알\.쓸\.신\.잡/알쓸신잡/' -e 's/HDTV\.//' -e 's/H264\.//')
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
