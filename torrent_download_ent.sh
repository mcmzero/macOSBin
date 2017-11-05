#!/bin/bash

function add_magnet() {
	transmission-remote router:9191 --auth moon:123123212121 $*
}

function get_magnet() {
	curl -s "${*}" | grep "magnet:" | sed -e "s/\" style.*//" -e "s/.*\"//"
}

function download_page() {
	if [ "${1}" == "" ]; then
		PAGE_NUM=1
	else
		PAGE_NUM=$1
	fi

	URL="https://ttocorps.com/bbs/board.php?bo_table=torrent_kortv_ent&page=${PAGE_NUM}"
	echo "${URL}"
	for URL in $(curl -s "${URL}"|grep 720p-NEXT|grep ttocorps.com|grep wr_id|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//' | head -n ${2})
	do
		MAGNET=$(get_magnet "${URL}")
		echo add_magnet "-a ${MAGNET}"
		add_magnet "-a ${MAGNET}"
	done
}

function download_ent() {
	CHECK_FILE=$(ls -tr "/media/torrent/${1}" | grep $(date +%y%m%d))
	echo $CHECK_FILE
	if [ "${CHECK_FILE}" == "" ]; then
		download_page 1 1 "${2}"
	fi
}

download_page 1 1000
#download_ent "무한 도전" "무한"