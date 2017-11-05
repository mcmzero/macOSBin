#!/bin/bash

TORRENT_DIR=/Share/Torrent
SOURCE_DIR=/Volumes/Movies/Torrent
TARGET_DIR=/volumes/Movies/TV

function rebuild() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi

	cd "${TRG_DIR}"
	echo Rebuild ${TRG_DIR}

	for FILE in *
	do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" == "[" ]; then
			echo Pass: ${FILE}
		else
			find "${TRG_DIR}/${FILE}" -name "*.mp4" -exec mv -v '{}' ${SRC_DIR} \;
		fi
	done

	for FILE in *
	do
		if [ -d "${FILE}" ] && [ "$(echo ${FILE} | cut -c 1)" != "[" ]; then
			find "${TRG_DIR}/${FILE}" -name ".DS_Store" -exec rm '{}' \;
			rmdir "${FILE}" 2> /dev/null && echo rmdir "${FILE}"
		fi
	done
	echo
}

function build_mp4_catagory() {
	SRC_DIR=$1
	if [ "${2}" != "" ]; then
		TRG_DIR=$2
	else
		TRG_DIR=$1
	fi

	if [ "${SRC_DIR}" != "${TRG_DIR}" ]; then
		find "${SRC_DIR}" -name "*.mp4" -exec mv '{}' \. \;
	fi

	cd "${SRC_DIR}"
	echo Build ${SRC_DIR}

	for FILE in *.mp4
	do
		if [ "${FILE}" != "*.mp4" ]; then
			TARGET_NAME=$(echo $FILE | cut -d "]" -f 2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/....p-NEXT//' -e 's/\.\./\./' -e 's/\.END//' -e 's/알\.쓸\.신\.잡/알쓸신잡/' -e 's/HDTV\.//' -e 's/H264\.//')
			DIR_NAME=${TRG_DIR}/$(echo $TARGET_NAME | cut -d . -f 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
			if [ ! -d "${DIR_NAME}" ]; then
				echo mkdir -pv "${DIR_NAME}"
				mkdir -pv "${DIR_NAME}"
			fi
			mv -fv "${FILE}" "${DIR_NAME}/${TARGET_NAME}"
		fi
	done
	echo
}

case "${1}" in
rbt)
	rebuild ${TORRENT_DIR}
	build_mp4_catagory ${TORRENT_DIR}
;;
t*)
	build_mp4_catagory ${TORRENT_DIR}
;;
rb)
	rebuild ${SOURCE_DIR} ${TARGET_DIR}
	build_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
;;
*)
	build_mp4_catagory ${SOURCE_DIR} ${TARGET_DIR}
;;
esac

