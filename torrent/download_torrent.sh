#!/bin/bash

source /usr/local/torrent/download_server_address
[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

defaultTorrentQuality=720
defaultTorrentCount=100

magnetList_FILE="/usr/local/torrent/magnet_list"
COOKIE_TCOREA="/usr/local/torrent/cookie_tcorea"

ENT=0
DRA=1
SOC=2

COR=0
KIM=1
PON=2

URL_SERVER[$COR]="https://www.tcorea.com"
URL_SERVER[$KIM]="https://torrentkim.pro"
URL_SERVER[$PON]="https://torrentpong.com"

URL_COR[$ENT]="${URL_SERVER[$COR]}/bbs/board.php?bo_table=torrent_kortv_ent"
URL_COR[$DRA]="${URL_SERVER[$COR]}/bbs/board.php?bo_table=torrent_kortv_drama"
URL_COR[$SOC]="${URL_SERVER[$COR]}/bbs/board.php?bo_table=torrent_kortv_social"

URL_KIM[$ENT]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_variety"
URL_KIM[$DRA]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_tv"
URL_KIM[$SOC]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_docu"

URL_PON[$ENT]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=ent"
URL_PON[$DRA]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=kordrama"
URL_PON[$SOC]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=dacu"

function downloadTorrentHelp() {
	#downloadTorrent count page_max_num quality(360 720 1080) search text
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

function downloadLogin_cor() {
	echo login to cor
	curl -s "https://www.tcorea.com/bbs/login_check.php" -c $COOKIE_TCOREA -d 'mb_id=mcmtor' -d 'mb_password=123123'
	cat $COOKIE_TCOREA
}

function downloadLogin_kim() {
	echo login to kim
}

function downloadLogin_pon() {
	echo login to pong
}

function setServer() {
	TOR_SERVER="$@":9191
}

function setServerLocal() {
	TOR_SERVER=localhost:$TOR_SERVER_PORT
}

function setServerConfig() {
	if [ "$(hostname -s |cut -c 1-4)" == "iMac" ]; then
		[ "$(ps x|grep Transmission|grep App)" == "" ] && setServer "$TOR_SERVER_IMAC" || setServerLocal
	fi
}

function listMagnetTail() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list | tail -n 1
}

function listMagnet() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list
}

function removeMagnet() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent "$*" --remove
}

function purgeTorrent() {
	local purgeTorServer=$TOR_SERVER
	[ "$1" != "" ] && purgeTorServer=$1

	local tempfoo=$(basename $0).XXX
	temp_maglist=$(mktemp -q -t $tempfoo)
	if [ $? -ne 0 ]; then
		echo "$0: Can't create temp file, exiting..."
		return 1
	fi

	local torrentIdList=$(listMagnet | tee ${temp_maglist} | grep "Stopped\|Seeding\|Finished\|Idle" | grep "100%" | sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//' | cut -d ' ' -f 1)
	if [ "$torrentIdList" != "" ]; then
		echo "transmission-remote ${purgeTorServer} --auth ${TOR_AUTH} --torrent ${torrentIdList// /,} --remove"
		transmission-remote ${purgeTorServer} --auth ${TOR_AUTH} --torrent ${torrentIdList// /,} --remove
	fi

	# 다운로드 항목이 없을때만 폴더 정리
	if [ "$(tail -n 1 ${temp_maglist})" == "Sum: None 0.0 0.0" ]; then
		source /usr/local/torrent/download_rebuild_torrent.sh
		cleanupRaspiDropbox
		rebuildRaspiDropbox
	fi

	rm -f ${temp_maglist}
}

function addMagnet() {
	transmission-remote ${TOR_SERVER} --auth moon:123123212121 $(echo "$@" | sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//')
}

function getMagnetList() {
	local magnetList=""
	local magnetCount=0
	local magnetListDateFile="${magnetList_FILE}_$(date +%m)"
	echo $magnetListDateFile $#
	for magnet in $@; do
		if [ "$magnet" != "" ]; then
			magnet=$(echo ${magnet}|tr '[:upper:]' '[:lower:]')
			local magnet_exist=$magnet
			grep --ignore-case $magnet ${magnetList_FILE}_* > /dev/null && magnet=""
			if [ "$magnet" != "" ]; then
				echo "$magnet $(date +"%Y.%m.%d %T")" | tee -a $magnetListDateFile | tail -n 1
				let magnetCount=magnetCount+1
				magnetList="$magnetList -a $magnet"
				echo +[$magnet]
			else
				echo @[$magnet_exist]
			fi
		fi
	done
	if [ "$magnetList" != "" ]; then
		echo "검색 결과: 마그넷 ${magnetCount}개 발견"
		addMagnet "${magnetList}"
	fi
}

##################
## torrent corea
##
function printMagnet_cor() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*" -b "$COOKIE_TCOREA"|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep magnet:|grep "$quality"|head -n "$count"|sed -e's/.*href=.//' -e's/\" id=.*//' -e's/.>.*//'
}

function downloadTorrent_cor() {
	# downloadTorrentCor count start_page end_page quality search
	local count=1
	local pageNumStart=1
	local pageNumEnd=1
	local quality="${defaultTorrentQuality}p-"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumStart=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				pageNumEnd=$1
				shift; var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	local search=$*
	search=${search// /+}
	echo "검색 [$search]"

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		for n in ${!URL_COR[@]}; do
			urlString="${URL_COR[n]}&page=${pageNum}&stx=${search}"
			echo search: $urlString
			urlRet=$(printMagnet_cor $quality $count $urlString)
			if [ "$urlRet" != "" ]; then
				urlList="$urlList $urlRet"
				break;
			fi
		done
	done

	getMagnetList ${urlList}
}

function downloadTorrent() {
	# downloadTorrent count page quality search
	local count=1
	local pageNumStart=1
	local pageNumEnd=1
	local quality="${defaultTorrentQuality}p-"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumEnd=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				quality="${1}p-"
				shift
			fi
		fi
	fi

	local search=$*
	search=${search// /+}

	downloadTorrentCor $count $pageNumStart $pageNumEnd ${quality//p-/} $search
}

function download_cor() {
	# download_cor count pageNum quality
	local count=$defaultTorrentCount
	local pageNumStart=1
	local pageNumEnd=2
	local quality="${defaultTorrentQuality}p-NEXT"
	local search="${defaultTorrentQuality}p-NEXT"
	local urlType=""
	case $1 in
		ent)    urlType=${URL_COR[$ENT]} ;;
		drama)  urlType=${URL_COR[$DRA]} ;;
		social) urlType=${URL_COR[$SOC]} ;;
		*)		return 1;;
	esac

	shift
	local var=$1
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumEnd=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${urlType}&page=${pageNum}&stx=${search}"
		echo search: $urlString
		urlRet=$(printMagnet_cor $quality $count $urlString)
		[ "$urlRet" != "" ] && urlList="$urlList $urlRet"
	done

	getMagnetList ${urlList}
}

################
## torrent kim
##
function downloadTorrent_kim() {
	# downloadTorrentKim count start_page end_page quality search
	local count=1
	local pageNumStart=1
	local pageNumEnd=1
	local quality="${defaultTorrentQuality}p-"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumStart=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				pageNumEnd=$1
				shift; var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	local search=$*
	search=${search// /+}
	echo "검색 [$search]"

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${URL_SERVER[$KIM]}/bbs/s.php?page=${pageNum}&k=${search}"
		echo search kim: $urlString
		IFS=$'\n'
		declare -a htmlArray=($(curl -s "${urlString}"))
		declare -a magnetArray=($(for n in ${!htmlArray[@]}; do echo "${htmlArray[n]}"|grep :Mag_dn|sed -e's/.*(./magnet:?xt=urn:btih:/' -e's/.).*//'; done))
		declare -a nameArray=($(for n in ${!htmlArray[@]}; do echo "${htmlArray[n]}"|grep '	</a>'|grep -ve'제휴'|sed -e's/<.a>//' -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'; done))
		IFS=$' \t\n'
		for n in ${!magnetArray[@]}; do
			((n >= count)) && break
			urlRet=$(echo ${nameArray[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
			if [ "$urlRet" != "" ]; then
				urlList="$urlList ${magnetArray[n]}"
				echo ${magnetArray[n]} ${nameArray[n]}
			fi
		done
		unset -v htmlArray magnetArray nameArray
	done

	getMagnetList ${urlList}
}

function download_kim() {
	# download_kim count pageNum quality
	local count=$defaultTorrentCount
	local pageNumStart=1
	local pageNumEnd=2
	local quality="${defaultTorrentQuality}p-NEXT"
	local search="${defaultTorrentQuality}p-NEXT"
	local urlType=""
	case $1 in
		ent)	urlType=${URL_KIM[$ENT]} ;;
		drama)	urlType=${URL_KIM[$DRA]} ;;
		social)	urlType=${URL_KIM[$SOC]} ;;
		*)		return 1;;
	esac

	shift
	local var=$1
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumEnd=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${urlType}&page=${pageNum}&k=${search}"
		echo search kim: $urlString
		IFS=$'\n'
		declare -a htmlArray=($(curl -s "${urlString}"))
		declare -a magnetArray=($(for n in ${!htmlArray[@]};do echo "${htmlArray[n]}"|grep :Mag_dn|sed -e's/.*(./magnet:?xt=urn:btih:/' -e's/.).*//';done))
		declare -a nameArray=($(for n in ${!htmlArray[@]};do echo "${htmlArray[n]}"|sed -e's/^[[:space:]]*//'|grep '</a>'|grep -ve'^<' -ve'href' -ve'제휴'|head -n $count|sed -e's/<.a>//' -e's/[[:space:]]*$//';done))
		IFS=$' \t\n'
		for n in ${!magnetArray[@]}; do
			((n >= count)) && break
			urlRet=$(echo ${nameArray[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
			if [ "$urlRet" != "" ]; then
				urlList="$urlList ${magnetArray[n]}"
				echo ${magnetArray[n]} ${nameArray[n]}
			fi
		done
		unset -v htmlArray magnetArray nameArray
	done

	getMagnetList ${urlList}
}

####################
## torrentpong.com
##
function printMagnet_pon() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*"|grep magnet|grep href|grep "$quality"|head -n "$count"|sed -e's/.*href=.//' -e's/..title=.*//'
}

function downloadTorrent_pon() {
	# downloadTorrent_pong count start_page end_page quality search
	local count=1
	local pageNumStart=1
	local pageNumEnd=1
	local quality="${defaultTorrentQuality}p-"
	local var=$1

	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumStart=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				pageNumEnd=$1
				shift; var=$1
				if ((var > 0)) 2> /dev/null; then
					quality="${1}p-"
					shift
				fi
			fi
		fi
	fi

	local search=$*
	search=${search// /+}
	echo "검색 [$search]"

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		for n in ${!URL_PON[@]}; do
			urlString="${URL_PON[n]}&page=${pageNum}&stx=${search}"
			echo search: $urlString
			urlRet=$(printMagnet_pon $quality $count $urlString)
			if [ "$urlRet" != "" ]; then
				urlList="$urlList $urlRet"
				break;
			fi
		done
	done

	getMagnetList ${urlList}
}

function download_pon() {
	# download_ent count pageNum quality
	local count=$defaultTorrentCount
	local pageNumStart=1
	local pageNumEnd=2
	local quality="${defaultTorrentQuality}p-NEXT"
	local search="${defaultTorrentQuality}p-NEXT"
	local urlType=""
	case $1 in
		ent)	urlType=${URL_PON[$ENT]} ;;
		drama)	urlType=${URL_PON[$DRA]} ;;
		social)	urlType=${URL_PON[$SOC]} ;;
		*)		return 1;;
	esac

	shift
	local var=$1
	if ((var > 0)) 2> /dev/null; then
		count=$1
		shift; var=$1
		if ((var > 0)) 2> /dev/null; then
			pageNumEnd=$1
			shift; var=$1
			if ((var > 0)) 2> /dev/null; then
				search="${1}p-NEXT"
				shift
			fi
		fi
	fi

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${urlType}&page=${pageNum}&stx=${search}"
		echo search: $urlString
		urlRet=$(printMagnet_pon $quality $count $urlString)
		[ "$urlRet" != "" ] && urlList="$urlList $urlRet"
	done

	getMagnetList ${urlList}
}
