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

	URL="https://ttocorps.com/bbs/board.php?bo_table=torrent_kortv_drama&sca=&sfl=wr_subject&stx=%EB%8B%AC%EC%88%9C%EC%95%84&page=${PAGE_NUM}"
	echo "${URL}"
	for URL in $(curl -s "${URL}"|grep 360p-NEXT|grep ttocorps.com|grep wr_id|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//' | head -n ${2})
	do
		MAGNET=$(get_magnet "${URL}")
		echo add_magnet "-a ${MAGNET}"
		add_magnet "-a ${MAGNET}"
	done
}

download_page 1 1000
