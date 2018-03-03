#!/bin/bash

source /usr/local/torrent/download_server_address
[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

URL_SERVER="https://www.tcorea.com"
URL_TYPE_ENT="${URL_SERVER}/bbs/board.php?bo_table=torrent_kortv_ent"
URL_TYPE_DRAMA="${URL_SERVER}/bbs/board.php?bo_table=torrent_kortv_drama"
URL_TYPE_SOCIAL="${URL_SERVER}/bbs/board.php?bo_table=torrent_kortv_social"

URL_SERVER_KIM="https://torrentkim12.com"
URL_TYPE_ENT_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_variety"
URL_TYPE_DRAMA_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_tv"
URL_TYPE_SOCIAL_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_docu"

COOKIE_TCOREA="/usr/local/torrent/cookie_tcorea"

function download_torrent_help() {
	#download_torrent count page_max_num quality(360 720 1080) search text
	echo "기본 사용법:"
	echo "download se 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "download 개수 최대페이지 화질(360 720 1080) 검색어"
	echo "download 개수 최대페이지 화질(360 720 1080)"
	echo "download 개수 최대페이지 검색어"
	echo "download 개수 최대페이지"
	echo "download 개수 검색어"
	echo "download 개수"
	echo "download 검색어"
	echo "download ep 에피소드시작 에피소드끝 제목"
	echo "download kim ep 에피소드시작 에피소드끝 제목"
	echo
	echo "예제:"
	echo "download 100 5 720 동상이몽2"
	echo "download 1 1 360 TV소설 꽃피어라 달순아"
	echo "download 1 1 720 황금빛 내 인생"
	echo "download 1 1 720 무한 도전"
	echo "download 100 2 720 아는 형님"
	echo "download ep 1 12 개그 콘서트"
	echo "download kim ep 1 12 맛있는 녀석들"
	echo
}

function login_tcorea() {
	curl -s https://www.tcorea.com/bbs/login_check.php -c $COOKIE_TCOREA -d 'mb_id=mcmtor' -d 'mb_password=123123'
	cat $COOKIE_TCOREA
}

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

function list_magnet_tail() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list | tail -n 1
}

function list_magnet() {
	# transmission-remote 192.168.0.3:9191 --auth moon:123123212121 --list
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

	# 다운로드 항목이 없을때만 폴더 정리
	source /usr/local/torrent/download_rebuild_torrent.sh
	TLT=$(cat ${TOR_LIST_TEMP}|tail -n 1)
	[ "$(echo $TLT)" == "Sum: None 0.0 0.0" ] && cleanup_raspi_dropbox && rebuild_raspi_dropbox

	rm -f ${TOR_LIST_TEMP}
}

function add_magnet() {
	transmission-remote ${TOR_SERVER} --auth moon:123123212121 $(echo "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

MAGNET_LIST_FILE="/usr/local/torrent/download_torrent_magnet_list.txt"
function get_magnet_list() {
	MAGNET_LIST=""
	MAGNET_COUNT=0
	for MAGNET in $@; do
		if [ "$MAGNET" != "" ]; then
			MAGNET_EXIST=$MAGNET
			grep $MAGNET $MAGNET_LIST_FILE > /dev/null && MAGNET=""
			if [ "$MAGNET" != "" ]; then
				echo $MAGNET >> $MAGNET_LIST_FILE;
				let MAGNET_COUNT=MAGNET_COUNT+1
				MAGNET_LIST="$MAGNET_LIST -a $MAGNET"
				echo +[$MAGNET]
			else
				echo @[$MAGNET_EXIST]
			fi
		fi
	done
	echo "검색 결과: 마그넷 ${MAGNET_COUNT}개 발견"
	[ "$MAGNET_LIST" != "" ] &&	add_magnet "${MAGNET_LIST}"
}

function print_magnet() {
	QUALITY="$1"
	shift
	COUNT="$1"
	shift
	URL="$*"
	MAGNET_RET="$(curl -s "$URL" -b "$COOKIE_TCOREA"|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep magnet:|grep "$QUALITY"|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/.>.*//')"
	echo $MAGNET_RET
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
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		#[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"

		URL="${URL_TYPE_DRAMA}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue

		URL="${URL_TYPE_SOCIAL}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done

	get_magnet_list ${URL_LIST}
}

function download_ent() {
	# download_ent count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_drama() {
	# download_drama count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_social() {
	# download_social count page_num quality
	COUNT=1
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_torrent_startend() {
	# download_torrent count start_page end_page quality search
	COUNT=1
	PAGE_NUM_START=1
	PAGE_NUM_END=1
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
			PAGE_NUM_START=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				PAGE_NUM_END=$1
				shift
				VAR=$1
				if ((VAR > 0)) 2> /dev/null
				then
					QUALITY="${1}p-NEXT"
					shift
				fi
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# grep -v 제외 문자열
	URL_LIST=""
	for PAGE_NUM in $(eval echo {$PAGE_NUM_START..$PAGE_NUM_END}); do
		URL="${URL_TYPE_ENT}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		#[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"

		URL="${URL_TYPE_DRAMA}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue

		URL="${URL_TYPE_SOCIAL}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet $QUALITY $COUNT $URL)
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done

	get_magnet_list ${URL_LIST}
}

###############
## torrent kim
##
function download_torrent_kim() {
	# download_torrent_kim count start_page end_page quality search
	COUNT=1
	PAGE_NUM_START=1
	PAGE_NUM_END=1
	QUALITY="720p-"
	SEARCH=""

	VAR=$1
	if ((VAR > 0)) 2> /dev/null
	then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null
		then
			PAGE_NUM_START=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null
			then
				PAGE_NUM_END=$1
				shift
				VAR=$1
				if ((VAR > 0)) 2> /dev/null
				then
					QUALITY="${1}p-"
					shift
				fi
			fi
		fi
	fi

	SEARCH="$*"
	PATTERN="$(echo "$SEARCH" | sed -e 's/ /+/g')"
	echo $SEARCH
	echo $PATTERN

	MAGNET_COUNT=0
	for PAGE_NUM in $(eval echo {$PAGE_NUM_START..$PAGE_NUM_END}); do
		echo PAGENUM: $PAGE_NUM
		MAGNET_LIST=""
		for ITEM in $(curl -s "${URL_SERVER_KIM}/bbs/s.php?k=${PATTERN}&page=${PAGE_NUM}"|grep href|grep torrent_|grep target=\'s\'|sed -e 's/.*href=...\/\(.*\)\/\([0-9]*\).html[^0-9]*/\1\&wr_id=\2/'); do
			echo [$ITEM]
			URL=$(curl -s "${URL_SERVER_KIM}/bbs/magnet2.php?bo_table=${ITEM}")
			echo SEARCH: $URL
			URL_RET=$(echo $URL|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$SEARCH"|grep "$QUALITY"|sed -e 's/.*\(magnet.*\).dn.*/\1/')
			[ "${URL_RET}" != "" ] && MAGNET_LIST="$MAGNET_LIST -a $URL_RET" && let MAGNET_COUNT=MAGNET_COUNT+1 && echo $ITEM $URL_RET
			[ $MAGNET_COUNT -ge $COUNT ] && break;
		done
		[ "$MAGNET_LIST" != "" ] && add_magnet "${MAGNET_LIST}"
	done
	echo "검색 결과: 마그넷 ${MAGNET_COUNT}개 발견"
}

function print_magnet_kim() {
	COUNT="$1"
	shift
	URL="$*"
	MAGNET_RET="$(curl -s "$URL"|grep Mag_dn|grep href|head -n $COUNT|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//')"
	echo $MAGNET_RET
}

function download_ent_kim() {
	# download_ent count page_num quality
	COUNT=100
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $COUNT $URL)
		#echo E[$URL][$PAGE_NUM][$URL_RET][$COUNT]
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_drama_kim() {
	# download_drama count page_num quality
	COUNT=100
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $COUNT $URL)
		#echo D[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}

function download_social_kim() {
	# download_social count page_num quality
	COUNT=100
	PAGE_MAX_NUM=2
	QUALITY="720p-NEXT"
	SEARCH="720p-NEXT"

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
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $COUNT $URL)
		#echo S[$URL][$PAGE_NUM][$URL_RET][$COUNT] $COUNT
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET" && continue
	done
	get_magnet_list ${URL_LIST}
}
