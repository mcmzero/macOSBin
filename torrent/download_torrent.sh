#!/bin/bash
source /usr/local/torrent/download_server_address

[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

function set_server() {
	TOR_SERVER="$@":9191
}

function set_server_local() {
	TOR_SERVER=localhost:$TOR_SERVER_PORT
}

function set_server_config() {
	if [ "$(hostname -s |cut -c 1-4)" == "iMac" ]; then
		[ "$(ps x|grep Transmission|grep App)" == "" ] && set_server "$TOR_SERVER_IMAC" || set_server_local
	fi
}

function list_magnet() {
	# tranmission-remote 192.168.0.3:9191 --auth moon:123123212121s --list
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list
}

function remove_magnet() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove
}

function purge_torrent() {
	[ "${1}" != "" ] && TOR_SERVER=${1} || 
	TOR_LIST_TEMP=`mktemp -q`

	list_magnet >& ${TOR_LIST_TEMP}
	cat ${TOR_LIST_TEMP}

	TORRENT_ID_LIST=`cat ${TOR_LIST_TEMP} | grep "Stopped\|Seeding\|Finished\|Idle" | grep "100%" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -d ' ' -f 1`
	TORRENT_ID_LIST=`echo ${TORRENT_ID_LIST} | sed -e 's/ /,/g'`

	if [ "$TORRENT_ID_LIST" != "" ]; then
		echo "transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove"
		transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove
	fi
	rm -f ${TOR_LIST_TEMP}
}

function add_magnet() {
	transmission-remote ${TOR_SERVER} --auth moon:123123212121 $(echo "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function get_magnet_list() {
	MAGNET_LIST=""
	MAGNET_COUNT=0
	for URL in $@
	do
		MAGNET=$(curl -s "${URL}" | grep "magnet:" | sed -e "s/\" style.*//" -e "s/.*\"//")
			if [ "$MAGNET" != "" ]; then
			let MAGNET_COUNT=MAGNET_COUNT+1
			MAGNET_LIST="$MAGNET_LIST -a $MAGNET"
			echo $MAGNET
		fi
	done
	echo "검색 결과: 마그넷 ${MAGNET_COUNT}개 발견"
	[ "$MAGNET_LIST" != "" ] &&	add_magnet "${MAGNET_LIST}"
}

URL_TYPE_DRAMA="https://ttocorps.com/bbs/board.php?bo_table=torrent_kortv_drama"
URL_TYPE_ENT="https://ttocorps.com/bbs/board.php?bo_table=torrent_kortv_ent"
URL_TYPE_SOCIAL="https://ttocorps.com/bbs/board.php?bo_table=torrent_kortv_social"

function download_torrent() {
	# download_torrent count page quality search
	COUNT=1
	PAGE_MAX_NUM=1
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		#COUNT=$((${1}+1))
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# grep -v 제외 문자열
	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue

		URL="${URL_TYPE_DRAMA}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		#echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue

		URL="${URL_TYPE_SOCIAL}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done

	get_magnet_list ${URL_LIST}
}

function download_drama() {
	# download_drama count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_ent() {
	# download_ent count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_social() {
	# download_social count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				QUALITY="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL}&page=${PAGE_NUM}&stx=${SEARCH}"
		URL_RET="$(curl -s "$URL"|grep -v 전편|grep -v 완결|grep media-list-subject|grep $QUALITY|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/\">.*//')"
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_torrent_help() {
	#download_torrent count page_max_num quality(360 720 1080) search text
	echo "기본 사용법:"
	echo "download 개수 최대페이지 화질(360 720 1080) 검색어"
	echo "download 개수 최대페이지 화질(360 720 1080)"
	echo "download 개수 최대페이지 검색어"
	echo "download 개수 최대페이지"
	echo "download 개수 검색어"
	echo "download 개수"
	echo "download 검색어"
	echo
	echo "예제:"
	echo "download 100 5 720 동상이몽2"
	echo "download 1 1 360 TV소설 꽃피어라 달순아"
	echo "download 1 1 720 황금빛 내 인생"
	echo "download 1 1 720 무한 도전"
	echo "download 100 2 720 아는 형님"
	echo
}
