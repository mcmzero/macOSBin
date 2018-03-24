#!/bin/bash

source /usr/local/torrent/torrent_server_address.sh
[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

defaultTorrentQuality=720
defaultTorrentCount=100

disposeFile="/usr/local/torrent/torrent_dispose.sh"
magnetListFile="/usr/local/torrent/magnet_list"
cookieFile_cor="/usr/local/torrent/cookie_tcorea"

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

URL_PON[$ENT]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=ent"
URL_PON[$DRA]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=kordrama"
URL_PON[$SOC]="${URL_SERVER[$PON]}/bbs/board.php?bo_table=dacu"

URL_KIM[$ENT]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_variety"
URL_KIM[$DRA]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_tv"
URL_KIM[$SOC]="${URL_SERVER[$KIM]}/bbs/s.php?b=torrent_docu"

function torrentLogin_cor() {
	echo login to cor
	curl -s "https://www.tcorea.com/bbs/login_check.php"\
		-c $cookieFile_cor -d 'mb_id=mcmtor' -d 'mb_password=123123'
	cat $cookieFile_cor
}

function torrentLogin_kim() {
	echo login to kim
}

function torrentLogin_pon() {
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

function transServer() {
	local server=$1
	shift
	transmission-remote ${server} --auth ${TOR_AUTH} $@
}

function transDefault() {
	transServer ${TOR_SERVER} $@
}

function magnetList() {
	transDefault --list
}

function magnetRemove() {
	transDefault --torrent "$*" --remove
}

function torrentPurge() {
	local server=$TOR_SERVER
	[ "$1" != "" ] && server=$1

	local tempMagnetList=$(mktemp -q -t $(basename $0).XXX)
	if [ $? -ne 0 ]; then
		echo "$0: Can't create temp file, exiting..."
		return 1
	fi

	local torrentIdList=$(transServer $server -l|tee ${tempMagnetList}|\
		grep "Stopped\|Seeding\|Finished\|Idle"|grep "100%"|\
		sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'|cut -d' ' -f1)
	torrentIdList=$(echo ${torrentIdList}|sed -e 's/ /,/g')
	if [ "$torrentIdList" != "" ]; then
		transServer $server --torrent ${torrentIdList} --remove
	fi

	# 다운로드 항목이 없을때만 폴더 정리
	if [ "$(tail -n 1 ${tempMagnetList})" == "Sum: None 0.0 0.0" ]; then
		source $disposeFile
		cleanupRaspiDropbox
	fi

	rm -f ${tempMagnetList}
}

function magnetAdd() {
	transDefault $(echo "$@" | sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//')
}

function magnetListAdd() {
	local magnetList=""
	local magnetCount=0
	local magnetListDateFile="${magnetListFile}_$(date +%m)"
	echo $magnetListDateFile $#
	for magnet in $@; do
		if [ "$magnet" != "" ]; then
			magnet=$(echo ${magnet}|tr '[:upper:]' '[:lower:]')
			local magnet_exist=$magnet
			grep --ignore-case $magnet ${magnetListFile}_* > /dev/null && magnet=""
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
		magnetAdd "${magnetList}"
	fi
}

function torrentSearch() {
	# torrentSearch count page quality search
	torrentSearch_cor $@
	torrentSearch_pon $@
	torrentSearch_kim $@
}

##################
## torrent corea
##
function printMagnet_cor() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*" -b "$cookieFile_cor"|\
		grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|\
		grep magnet:|grep "$quality"|head -n "$count"|\
		sed -e's/.*href=.//' -e's/\" id=.*//' -e's/.>.*//'
}

function torrentSearch_cor() {
	# torrentSearchCor count start_page end_page quality search
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

	magnetListAdd ${urlList}
}

function torrentCategory_cor() {
	# torrentCategory_cor count pageNum quality
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

	magnetListAdd ${urlList}
}

####################
## torrentpong.com
##
function printMagnet_pon() {
	local quality="$1"
	shift
	local count="$1"
	shift
	curl -s "$*"|grep magnet|grep href|grep "$quality"|\
		head -n "$count"|sed -e's/.*href=.//' -e's/..title=.*//'
}

function torrentSearch_pon() {
	# torrentSearch_pong count start_page end_page quality search
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

	magnetListAdd ${urlList}
}

function torrentCategory_pon() {
	# torrentCategory_ent count pageNum quality
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

	magnetListAdd ${urlList}
}

################
## torrent kim
##
function torrentSearch_kim() {
	# torrentSearchKim count start_page end_page quality search
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

	local outputFile=$(mktemp -q -t $(basename $0)_list.XXXXX)
	local htmlFile=$(mktemp -q -t $(basename $0)_html.XXXXX)

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${URL_SERVER[$KIM]}/bbs/s.php?page=${pageNum}&k=${search}"
		echo search kim: $urlString

		IFS=$'\n'
		curl -s "$urlString" -o "$htmlFile"
		declare -a magnetArray=($(grep :Mag_dn ${htmlFile}|\
									sed -e's/.*(./magnet:?xt=urn:btih:/' -e's/.).*//'))
		declare -a nameArray=($(grep '	</a>' ${htmlFile}|grep -ve'제휴'|\
									sed -e's/<.a>//' -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'))
		IFS=$' \t\n'

		local matchCount=0
		for n in ${!magnetArray[@]}; do
			urlRet=$(echo ${nameArray[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
			if [ "$urlRet" != "" ]; then
				matchCount=$(($matchCount + 1))
				((matchCount > count)) && break
				urlList="$urlList ${magnetArray[n]}"
				#echo ${magnetArray[n]//magnet:?xt=urn:btih:/} ${nameArray[n]} >> $outputFile
				echo ${nameArray[n]} >> $outputFile
			fi
		done
		unset -v magnetArray nameArray
	done
	magnetListAdd ${urlList}

	cat $outputFile
	rm $outputFile $htmlFile
}

function torrentCategory_kim() {
	# torrentCategory_kim count pageNum quality
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

	local outputFile=$(mktemp -q -t $(basename $0)_list.XXXXX)
	local htmlFile=$(mktemp -q -t $(basename $0)_html.XXXXX)

	local urlList=""
	for pageNum in $(seq $pageNumStart $pageNumEnd); do
		urlString="${urlType}&page=${pageNum}&k=${search}"
		echo search kim: $urlString

		IFS=$'\n'
		curl -s "$urlString" -o "$htmlFile"
		declare -a magnetArray=($(grep :Mag_dn ${htmlFile}|sed -e's/.*(./magnet:?xt=urn:btih:/' -e's/.).*//'))
		declare -a nameArray=($(sed -e's/^[[:space:]]*//' ${htmlFile}|\
								grep '</a>'|grep -ve'^<' -ve'href' -ve'제휴'|\
								sed -e's/<.a>//' -e's/[[:space:]]*$//'))
		IFS=$' \t\n'

		local matchCount=0
		for n in ${!magnetArray[@]}; do
			urlRet=$(echo ${nameArray[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
			if [ "$urlRet" != "" ]; then
				matchCount=$(($matchCount + 1))
				((matchCount > count)) && break
				urlList="$urlList ${magnetArray[n]}"
				#echo ${magnetArray[n]//magnet:?xt=urn:btih:/} ${nameArray[n]} >> $outputFile
				echo ${nameArray[n]} >> $outputFile
			fi
		done
		unset -v magnetArray nameArray
	done
	magnetListAdd ${urlList}

	cat $outputFile
	rm $outputFile $htmlFile
}
