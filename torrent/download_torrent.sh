#!/bin/bash

SERVER_IP=192.168.0.1
[ "$(hostname|cut -c 1-4)" == "iMac" ] && SERVER_IP=localhost
TOR_IP_PORT=${SERVER_IP}:9191

URL_TYPE_DRAMA="torrent_kortv_drama"
URL_TYPE_ENT="torrent_kortv_ent"
URL_TYPE_SOCIAL="torrent_kortv_social"

function purge_torrent() {
	echo "Purge torrent"
	[ "${1}" == "" ] || TOR_IP_PORT=${1}
	TOR_USER=moon
	TOR_PASS=123123212121

	TORRENTLIST=`transmission-remote ${TOR_IP_PORT} --auth ${TOR_USER}:${TOR_PASS} --list | sed -e '1d;$d;s/^ *//' | cut --delimiter=' ' --fields=1`

	for TORRENTID in $TORRENTLIST
	do
		echo "* * * * * Operations on torrent ID $TORRENTID starting. * * * * *"

		DL_COMPLETED=`transmission-remote ${TOR_IP_PORT} --auth ${TOR_USER}:${TOR_PASS} --torrent $TORRENTID --info | grep "Percent Done: 100%"`
		STATE_STOPPED=`transmission-remote ${TOR_IP_PORT} --auth ${TOR_USER}:${TOR_PASS} --torrent $TORRENTID --info | grep "State: Stopped\|Seeding\|Finished\|Idle"`

		if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ]; then
			echo "Torrent #$TORRENTID is completed."
			echo "Removing torrent from list."
			transmission-remote ${TOR_IP_PORT} --auth ${TOR_USER}:${TOR_PASS} --torrent $TORRENTID --remove
		else
			echo "Torrent #$TORRENTID is not completed. Ignoring."
		fi

		echo "* * * * * Operations on torrent ID $TORRENTID completed. * * * * *"
	done
}

function add_magnet() {
	echo "마그넷 추가: ${TOR_IP_PORT} $(echo "$*"|cut -d ' ' -f 2)"
	transmission-remote ${TOR_IP_PORT} --auth moon:123123212121 $@
}

function get_magnet() {
        curl -s "${*}" | grep "magnet:" | sed -e "s/\" style.*//" -e "s/.*\"//"
}

function get_magnet_list() {
	for URL in $@
	do
		echo ${URL}
		MAGNET=$(get_magnet "${URL}")
		#echo add_magnet "--add ${MAGNET}"
		if [ "${MAGNET}" != "" ]; then
			echo
			add_magnet "--add ${MAGNET}"
		fi
	done
}

function download_torrent() {
	# download_torrent count page quality search
	COUNT=1
	PAGE_MAX_NUM=1
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=$((${1}+1))
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=${1}
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi
	SEARCH=$@
	echo "검색[$SEARCH]"

	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_DRAMA}&stx=${SEARCH}&page=${PAGE_NUM}"
		URL_DRAMA="$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|grep "${SEARCH}"|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})"
		[ "${URL_DRAMA}" != "" ] && echo "[드라마]" && echo "${URL_DRAMA}"

		URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_ENT}&stx=${SEARCH}&page=${PAGE_NUM}"
		URL_ENT="$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|grep "${SEARCH}"|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})"
		[ "${URL_ENT}" != "" ] && echo "[예능]" && echo "${URL_ENT}"

		URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_SOCIAL}&stx=${SEARCH}&page=${PAGE_NUM}"
		URL_SOCIAL="$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|grep "${SEARCH}"|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})"
		[ "${URL_SOCIAL}" != "" ] && echo "[교양]" && echo "${URL_SOCIAL}"

		get_magnet_list ${URL_DRAMA} ${URL_ENT} ${URL_SOCIAL}
	done
}

function download_drama() {
	# download_drama count page_num quality
	COUNT=1
	PAGE_MAX_NUM=1
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=${1}
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=${1}
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_DRAMA}&page=${PAGE_NUM}"
		URL_DRAMA=$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})
		[ "${URL_DRAMA}" != "" ] && echo "드라마: ${URL_DRAMA}"
		get_magnet_list ${URL_DRAMA}
	done
}

function download_ent() {
	# download_ent count page_num quality
	COUNT=1
	PAGE_MAX_NUM=1
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=${1}
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=${1}
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_ENT}&page=${PAGE_NUM}"
	URL_ENT=$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})
	[ "${URL_ENT}" != "" ] && echo "예능: ${URL_ENT}"

	get_magnet_list ${URL_ENT}
}

function download_social() {
	# download_social count page_num quality
	COUNT=1
	PAGE_NUM=1
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)); then
		COUNT=${1}
		shift
		VAR=$1
		if ((VAR > 0)); then
			PAGE_NUM=${1}
			shift
			VAR=$1
			if ((VAR > 0)); then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi
	SEARCH=$@

	URL="https://ttocorps.com/bbs/board.php?bo_table=${URL_TYPE_SOCIAL}&stx=${SEARCH}&page=${PAGE_NUM}"
	URL_SOCIAL=$(curl -s "${URL}"|grep "${QUALITY}"|grep ttocorps.com|grep wr_id|grep "${SEARCH}"|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//'|head -n ${COUNT})
	[ "${URL_SOCIAL}" != "" ] && echo "교양: ${URL_SOCIAL}"

	get_magnet_list ${URL_SOCIAL}
}

function download_torrent_help() {
	#download_torrent count page_max_num quality(360 720 1080) search text
	echo "download_torrent 개수 최대페이지 화질(360 720 1080) 검색어"
	echo "download_torrent 개수 최대페이지 화질(360 720 1080)"
	echo "download_torrent 개수 최대페이지 검색어"
	echo "download_torrent 개수 최대페이지"
	echo "download_torrent 개수 검색어"
	echo "download_torrent 개수"
	echo "download_torrent 검색어"
	echo "download_torrent 100 5 720 동상이몽2"
	echo "download_torrent 1 1 360 TV소설 꽃피어라 달순아"
	echo "download_torrent 1 1 720 황금빛 내 인생"
	echo "download_torrent 1 1 720 무한 도전"
	echo "download_torrent 100 2 720 아는 형님"
	exit
}
