#!/bin/bash

source /usr/local/torrent/download_server_address
[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

URL_SERVER_COR="https://www.tcorea.com"
URL_SERVER_KIM="https://torrentkim.pro"
URL_SERVER_PONG="https://torrentpong.com"

URL_TYPE_ENT_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_ent"
URL_TYPE_DRAMA_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_drama"
URL_TYPE_SOCIAL_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_social"
COOKIE_TCOREA="/usr/local/torrent/cookie_tcorea"

URL_TYPE_ENT_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_variety"
URL_TYPE_DRAMA_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_tv"
URL_TYPE_SOCIAL_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_docu"

URL_TYPE_ENT_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=ent"
URL_TYPE_DRAMA_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=kordrama"
URL_TYPE_SOCIAL_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=dacu"

MAGNET_LIST_FILE="/usr/local/torrent/magnet_list"

function download_torrent_help() {
	#download_torrent count page_max_num quality(360 720 1080) search text
	echo "사용법:"
	echo "download cor 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "download kim 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "download pong 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo
	echo "download cor ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "download kim ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "download pong ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo
	echo "download ent pagenum"
	echo "download drama pagenum"
	echo "download social pagenum"
	echo
	echo "download 사이트(cor kim pong) ent pagenum"
	echo "download 사이트(cor kim pong) drama pagenum"
	echo "download 사이트(cor kim pong) social pagenum"
	echo
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
	echo "download cor ep 1 12 720 개그 콘서트"
	echo "download kim ep 1 12 360 맛있는 녀석들"
	echo "download pong ep 1 12 1080 맛있는 녀석들"
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
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent "$*" --remove
}

function purge_torrent() {
	local purge_tor_server=$TOR_SERVER
	[ "$1" != "" ] && purge_tor_server=$1

	local tempfoo=$(basename $0).XXX
	temp_maglist=$(mktemp -q -t $tempfoo)
	if [ $? -ne 0 ]; then
		echo "$0: Can't create temp file, exiting..."
		return 1
	fi

	local torrent_id_list=$(list_magnet | tee ${temp_maglist} | grep "Stopped\|Seeding\|Finished\|Idle" | grep "100%" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -d ' ' -f 1)
	if [ "$torrent_id_list" != "" ]; then
		echo "transmission-remote ${purge_tor_server} --auth ${TOR_AUTH} --torrent ${torrent_id_list// /,} --remove"
		transmission-remote ${purge_tor_server} --auth ${TOR_AUTH} --torrent ${torrent_id_list// /,} --remove
	fi

	# 다운로드 항목이 없을때만 폴더 정리
	if [ "$(tail -n 1 ${temp_maglist})" == "Sum: None 0.0 0.0" ]; then
		source /usr/local/torrent/download_rebuild_torrent.sh
		cleanup_raspi_dropbox
		rebuild_raspi_dropbox
	fi

	rm -f ${temp_maglist}
}

function add_magnet() {
	transmission-remote ${TOR_SERVER} --auth moon:123123212121 $(echo "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

function get_magnet_list() {
	local magnet_list=""
	local magnet_count=0
	local magnet_list_date_file="${MAGNET_LIST_FILE}_$(date +%m)"
	echo $magnet_list_date_file $#
	for magnet in $@; do
		if [ "$magnet" != "" ]; then
			magnet=$(echo ${magnet}|tr '[:upper:]' '[:lower:]')
			local magnet_exist=$magnet
			grep --ignore-case $magnet ${MAGNET_LIST_FILE}_* > /dev/null && magnet=""
			if [ "$magnet" != "" ]; then
				echo "$magnet $(date +"%Y.%m.%d %T")" | tee -a $magnet_list_date_file | tail -n 1
				let magnet_count=magnet_count+1
				magnet_list="$magnet_list -a $magnet"
				echo +[$magnet]
			else
				echo @[$magnet_exist]
			fi
		fi
	done
	if [ "$magnet_list" != "" ]; then
		echo "검색 결과: 마그넷 ${magnet_count}개 발견"
		add_magnet "${magnet_list}"
	fi
}

##################
## torrent corea
##
function print_magnet_cor() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*" -b "$COOKIE_TCOREA"|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep magnet:|grep "$quality"|head -n "$count"|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/.>.*//'
}

function download_torrent_cor() {
	# download_torrent_cor count start_page end_page quality search
	local count=1
	local page_num_start=1
	local page_num_end=1
	local quality="720p-"
	local search=""
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_start=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				page_num_end=$1
				shift
				var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	search=$*
	search=${search// /+}
	echo "검색 [$search]"

	# grep -v 제외 문자열
	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"

		url_string="${URL_TYPE_DRAMA_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi

		url_string="${URL_TYPE_SOCIAL_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi
	done

	get_magnet_list ${url_list}
}

function download_torrent() {
	# download_torrent count page quality search
	local count=1
	local page_num_start=1
	local page_num_end=1
	local quality="720p-"
	local search=""
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				quality="${1}p-"
				shift
			fi
		fi
	fi

	search=$*
	search=${search// /+}
	echo "검색 [$search]"

	# grep -v 제외 문자열
	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
		fi

		url_string="${URL_TYPE_DRAMA_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi

		url_string="${URL_TYPE_SOCIAL_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi
	done

	get_magnet_list ${url_list}
}

function download_ent_cor() {
	# download_ent count page_num quality
	local count=1
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_drama_cor() {
	# download_drama count page_num quality
	local count=1
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_DRAMA_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_social_cor() {
	# download_social count page_num quality
	local count=1
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_SOCIAL_COR}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_cor $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

################
## torrent kim
##
function download_torrent_kim() {
	# download_torrent_kim count start_page end_page quality search
	local count=1
	local page_num_start=1
	local page_num_end=1
	local quality="720p-"
	local search=""
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_start=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				page_num_end=$1
				shift
				var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	search=$*
	search=${search// /+}
	echo "검색 [$search]"

	# declare -a magnet_array=($(curl -s "https://torrentkim12.com/bbs/s.php?k=720p-NEXT&b=torrent_variety&page=1"|grep Mag_dn|grep href|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//'))
	# IFS=$'\n';declare -a name_array=($(curl -s "https://torrentkim12.com/bbs/s.php?k=720p-NEXT&b=torrent_variety&page=1"|grep '\t</a>'|sed -e 's/^...//' -e 's/...<.a>//'));IFS=$' \t\n'

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_SERVER_KIM}/bbs/s.php?page=${page_num}&k=${search}"
		echo search kim: $url_string
		IFS=$'\n'
		declare -a magnet_array=($(curl -s "${url_string}"|grep Mag_dn|grep href|head -n $count|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//'))
		declare -a name_array=($(curl -s "${url_string}"|grep '	</a>'|head -n $count|sed -e 's/^...//' -e 's/...<.a>//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'))
		IFS=$' \t\n'
		for n in ${!magnet_array[@]}; do
			url_ret=$(echo ${name_array[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
			if [ "$url_ret" != "" ]; then
				url_list="$url_list ${magnet_array[n]}"
				echo [${name_array[n]}] ${magnet_array[n]}
			fi
		done
		unset -v magnet_array name_array
	done

	get_magnet_list ${url_list}
}

function print_magnet_kim() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*"|grep Mag_dn|grep href|head -n "$count"|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//'
}

function download_ent_kim() {
	# download_ent count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_KIM}&page=${page_num}&k=${search}"
		echo search kim: $url_string
		url_ret=$(print_magnet_kim $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_drama_kim() {
	# download_drama count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_DRAMA_KIM}&page=${page_num}&k=${search}"
		echo search kim: $url_string
		url_ret=$(print_magnet_kim $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_social_kim() {
	# download_social count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_SOCIAL_KIM}&page=${page_num}&k=${search}"
		echo search kim: $url_string
		url_ret=$(print_magnet_kim $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

####################
## torrentpong.com
##
# curl -s "https://torrentpong.com/bbs/board.php?bo_table=ent&page=1&stx=720p-NEXT"|grep magnet|grep 720p-NEXT
function print_magnet_pong() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*"|grep magnet|grep href|grep "$quality"|head -n "$count"|sed -e 's/.*href=.//' -e 's/..title=.*//'
}

function download_torrent_pong() {
	# download_torrent_pong count start_page end_page quality search
	local count=1
	local page_num_start=1
	local page_num_end=1
	local quality="720p-"
	local search=""
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_start=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				page_num_end=$1
				shift
				var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	search=$*
	search=${search// /+}
	echo "검색 [$search]"

	# grep -v 제외 문자열
	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
		fi

		url_string="${URL_TYPE_DRAMA_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi

		url_string="${URL_TYPE_SOCIAL_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		if [ "$url_ret" != "" ]; then
			url_list="$url_list $url_ret"
			continue
		fi
	done

	get_magnet_list ${url_list}
}

function download_ent_pong() {
	# download_ent count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_ENT_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_drama_pong() {
	# download_drama count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_DRAMA_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}

function download_social_pong() {
	# download_social count page_num quality
	local count=100
	local page_num_start=1
	local page_num_end=2
	local quality="720p-NEXT"
	local search="720p-NEXT"
	local var=$1
	
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift
		var=$1
		if ((var > 0)) 2> /dev/null; then
			page_num_end=$1
			shift
			var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local url_list=""
	for page_num in $(seq $page_num_start $page_num_end); do
		url_string="${URL_TYPE_SOCIAL_PONG}&page=${page_num}&stx=${search}"
		echo search: $url_string
		url_ret=$(print_magnet_pong $quality $count $url_string)
		[ "$url_ret" != "" ] && url_list="$url_list $url_ret"
	done
	get_magnet_list ${url_list}
}
