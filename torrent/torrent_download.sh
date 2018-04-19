#!/bin/bash
#
# torrent_download.sh <changmin811@gmail.com>

source /usr/local/torrent/torrent_server_address.sh
[ -z "$TOR_SERVER_IP" ] && TOR_SERVER_IP="localhost"
[ -z "$TOR_SERVER_PORT" ] && TOR_SERVER_PORT=9191

sqlite3="$(which sqlite3)"
[[ "$sqlite3" ]] && sqlite3="$sqlite3 /usr/local/torrent/magnet.db"
[[ $(grep pi /etc/passwd) ]] && sqlite3="sudo -u pi $sqlite3"
$sqlite3 "CREATE TABLE IF NOT EXISTS magnetList(magnet TEXT primary key, time INTEGER, name TEXT);"

function decode() {
    echo "$*" | base64 --decode -i -
}

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=$(decode "bW9vbjoxMjMxMjMyMTIxMjEK")

defaultTorrentQuality=720
defaultTorrentCount=100

disposeFile="/usr/local/torrent/torrent_dispose.sh"
magnetListFile="/usr/local/torrent/magnet_list"
magnetNameListFile="/usr/local/torrent/magnet_name_list"
cookieFile_cor="/usr/local/torrent/cookie_tcorea"

source $disposeFile

declare -a urlServer=(\
    "https://www.tcorea.com"\
    "https://torrentpong.com"\
    "https://torrentkim.pro"\
)

declare -a urlCor=(\
    "${urlServer[0]}/bbs/board.php?bo_table=torrent_kortv_ent"\
    "${urlServer[0]}/bbs/board.php?bo_table=torrent_kortv_drama"\
    "${urlServer[0]}/bbs/board.php?bo_table=torrent_kortv_social"\
)

declare -a urlPon=(\
    "${urlServer[1]}/bbs/board.php?bo_table=ent"\
    "${urlServer[1]}/bbs/board.php?bo_table=kordrama"\
    "${urlServer[1]}/bbs/board.php?bo_table=dacu"\
)

declare -a urlKim=(\
    "${urlServer[2]}/bbs/s.php?b=torrent_variety"\
    "${urlServer[2]}/bbs/s.php?b=torrent_tv"\
    "${urlServer[2]}/bbs/s.php?b=torrent_docu"\
)

function torrentLogin_cor() {
    echo login to cor
    local cor_id=$(decode "bWNtdG9yCg==")
    local cor_password=$(decode "MTIzMTIzCg==")
    curl -s "https://www.tcorea.com/bbs/login_check.php"\
        -c $cookieFile_cor -d "mb_id=$cor_id" -d "mb_password=$cor_password"
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
        [ -z "$(ps x|grep Transmission|grep App)" ] && setServer "$TOR_SERVER_IMAC" || setServerLocal
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

function magnetIdList() {
    transDefault -l|grep -ve'ID.*Name' -ve'Sum:.*'|\
                    sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'|\
                    cut -d' ' -f1
}

function torrentPurge() {
    local server=$TOR_SERVER
    [[ $1 ]] && server=$1

    local basename=$(basename $0 2> /dev/null||echo "torrent")
    local tempMagnetList=$(mktemp -q -t ${basename}.XXX)
    if [[ $? -ne 0 ]]; then
        echo "$0: Can't create temp file, exiting..."
        return 1
    fi

    local torrentIdList=$(transServer $server -l|grep -ve'ID.*Name' -ve'Sum:.*'|\
                            tee ${tempMagnetList}|\
                            grep "Stopped\|Seeding\|Finished\|Idle"|grep "100%"|\
                            sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'|\
                            cut -d' ' -f1)

    local telegramMsgText
    for tid in $torrentIdList; do
        local name=$(getTargetName $(transServer $server -t $tid -i|grep Name|cut -d' ' -f4-)|sed -e's/.mp4//' -e's/.mkv//' -e's/.avi//' -e's/.720p.*$//')
        local magnet=$(transServer $server -t $tid -i|grep Magnet|cut -d' ' -f4-|sed -e's/&dn.*$//')
        if [[ $name && $magnet ]]; then
            $sqlite3 "UPDATE magnetList SET name = '${name}' WHERE magnet == '$magnet'"
            #$sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'),magnet,name FROM magnetList WHERE magnet == '$magnet'" -separator ' ' >> /home/pi/telegramMsgText.txt
            telegramMsgText="${telegramMsgText}${name}\\n"
        fi
    done
    /usr/local/torrent/torrent_telegram.sh $telegramMsgText

    torrentIdList=$(echo ${torrentIdList}|sed -e 's/ /,/g')
    if [[ $torrentIdList ]]; then
        transServer $server --torrent ${torrentIdList} --remove
    fi

    # 다운로드 항목이 없을때 떨굼상자 안에 있는 폴더들을 검사하여 모든 동영상 파일을 떨꿈상자 폴더로 이동하고 하위 폴더를 제거(정리)한다
    if [[ -z "$(tail -n 1 ${tempMagnetList})" ]]; then
        cleanupRasPi
    fi
    rm -f ${tempMagnetList}
}

function magnetAdd() {
    transDefault $(echo "$@" | sed -e's/^[[:space:]]*//' -e's/[[:space:]]*$//')
}

function magnetListAdd() {
    local magnetList
    local magnetCount=0
    local magnetListDateFile="${magnetListFile}_$(date +%y%m)"
    echo $magnetListDateFile $#
    for magnet in $@; do
        if [ "$magnet" ]; then
            magnet=$(echo ${magnet}|tr '[:upper:]' '[:lower:]')
            if [ "$sqlite3" ]; then
                if $sqlite3 "INSERT INTO magnetList VALUES('$magnet', strftime('%s','now'), NULL);" 2> /dev/null; then
                    let magnetCount=magnetCount+1
                    magnetList="$magnetList -a $magnet"
                    echo "+[$magnet] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '$magnet';" -separator ' ')"
                elif [[ $forcedDownloadMode ]]; then
                    let magnetCount=magnetCount+1
                    magnetList="$magnetList -a $magnet"
                    echo "![$magnet] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '$magnet';" -separator ' ')"
                else
                    echo "@[$magnet] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '$magnet';" -separator ' ')"
                fi
            else
                local magnet_exist=$magnet
                grep --ignore-case "$magnet" ${magnetListFile}_* > /dev/null && magnet=""
                if [ "$magnet" ]; then
                    let magnetCount=magnetCount+1
                    magnetList="$magnetList -a $magnet"
                    echo "$magnet $(date +"%Y.%m.%d %T")" | tee -a $magnetListDateFile | tail -n 1
                    echo +[$magnet]
                else
                    echo @[$magnet_exist]
                fi
            fi
        fi
    done
    if [ -n "$magnetList" ]; then
        echo "검색 결과: 마그넷 ${magnetCount}개 발견"
        magnetAdd $magnetList
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
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumStart=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                pageNumEnd=$1; shift
                var=$1
                if ((var > 0)) 2> /dev/null; then
                    quality="${1}p-"; shift
                fi
            fi
        fi
    fi

    local search=$*
    search=${search// /+}
    echo "검색 [$search]"

    local urlList
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
        for n in ${!urlCor[@]}; do
            urlString="${urlCor[n]}&page=${pageNum}&stx=${search}"
            echo search: $urlString
            urlRet=$(printMagnet_cor $quality $count $urlString)
            if [ -n "$urlRet" ]; then
                urlList="$urlList $urlRet"
                #break
            fi
        done
    done

    magnetListAdd $urlList
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
        ent)    urlType=${urlCor[0]} ;;
        drama)  urlType=${urlCor[1]} ;;
        social) urlType=${urlCor[2]} ;;
        *)        return 1;;
    esac

    shift
    local var=$1
    if ((var > 0)) 2> /dev/null; then
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumEnd=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                search="${1}p-NEXT"; shift
            fi
        fi
    fi

    local urlList
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
        urlString="${urlType}&page=${pageNum}&stx=${search}"
        echo search: $urlString
        urlRet=$(printMagnet_cor $quality $count $urlString)
        [ -n "$urlRet" ] && urlList="$urlList $urlRet"
    done

    magnetListAdd $urlList
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
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumStart=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                pageNumEnd=$1; shift
                var=$1
                if ((var > 0)) 2> /dev/null; then
                    quality="${1}p-"; shift
                fi
            fi
        fi
    fi

    local search=$*
    search=${search// /+}
    echo "검색 [$search]"

    local urlList
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
        for n in ${!urlPon[@]}; do
            urlString="${urlPon[n]}&page=${pageNum}&stx=${search}"
            echo search: $urlString
            urlRet=$(printMagnet_pon $quality $count $urlString)
            if [ -n "$urlRet" ]; then
                urlList="$urlList $urlRet"
                #break
            fi
        done
    done

    magnetListAdd $urlList
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
        ent)    urlType=${urlPon[0]} ;;
        drama)    urlType=${urlPon[1]} ;;
        social)    urlType=${urlPon[2]} ;;
        *)        return 1;;
    esac

    shift
    local var=$1
    if ((var > 0)) 2> /dev/null; then
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumEnd=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                search="${1}p-NEXT"; shift
            fi
        fi
    fi

    local urlList
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
        urlString="${urlType}&page=${pageNum}&stx=${search}"
        echo search: $urlString
        urlRet=$(printMagnet_pon $quality $count $urlString)
        [ -n "$urlRet" ] && urlList="$urlList $urlRet"
    done

    magnetListAdd $urlList
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
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumStart=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                pageNumEnd=$1; shift
                var=$1
                if ((var > 0)) 2> /dev/null; then
                    quality="${1}p-"; shift
                fi
            fi
        fi
    fi

    local search=$*
    search=${search// /+}
    echo "검색 [$search]"

    local htmlFile=$(mktemp -q -t $(basename $0)_html.XXXXX)
    [[ $sqlite3 ]] || local outputFile=$(mktemp -q -t $(basename $0)_list.XXXXX)

    local magnetCount=0
    local magnetList
    local telegramMsgText
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
        urlString="${urlServer[2]}/bbs/s.php?page=${pageNum}&k=${search}"
        echo search kim: $urlString

        IFS=$'\n'
        curl -s "$urlString" -o "$htmlFile"
        declare -a magnetArray=($(grep :Mag_dn ${htmlFile}|\
                                sed -e's/.*(./magnet:?xt=urn:btih:/' -e's/.).*//'))
        declare -a nameArray=($(grep '    </a>' ${htmlFile}|grep -ve'제휴'|\
                                sed -e's/<.a>//' -e's/^[[:space:]]*//' -e's/[[:space:]]*$//'))
        IFS=$' \t\n'

        local matchCount=0
        for n in ${!magnetArray[@]}; do
            urlRet=$(echo ${nameArray[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$quality")
            if [[ $urlRet ]]; then
                matchCount=$(($matchCount + 1))
                ((matchCount > count)) && break
                magnetArray[n]=$(echo ${magnetArray[n]}|tr '[:upper:]' '[:lower:]')
                nameArray[n]=$(getTargetName ${nameArray[n]}|sed -e's/.mp4//' -e's/.mkv//' -e's/.avi//' -e's/.720p.*$//')
                if [[ $sqlite3 ]]; then
                    local result=$($sqlite3 "SELECT COUNT(*),name FROM magnetList WHERE magnet == '${magnetArray[n]}'")
                    local resultCount=$(echo $result|cut -d'|' -f1)
                    local resultName=$(echo $result|cut -d'|' -f2-)
                    if [[ $resultCount > 0 && $resultName == "" ]]; then
                        $sqlite3 "UPDATE magnetList SET name = '${nameArray[n]}' WHERE magnet == '${magnetArray[n]}' AND name IS NULL"
                        telegramMsgText="${telegramMsgText}#${nameArray[n]}\\n"
                    elif [[ $resultCount == 0 ]]; then
                        if $sqlite3 "INSERT INTO magnetList VALUES('${magnetArray[n]}', strftime('%s','now'), '${nameArray[n]}')"; then
                            let magnetCount=magnetCount+1
                            magnetList="$magnetList -a ${magnetArray[n]}"
                            telegramMsgText="${telegramMsgText}+${nameArray[n]}\\n"
                            echo "+[${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}'" -separator ' ')"
                        fi
                    elif [[ $forcedDownloadMode ]]; then
                        let magnetCount=magnetCount+1
                        magnetList="$magnetList -a ${magnetArray[n]}"
                        echo "![${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}';" -separator ' ')"
                    else
                        echo "@[${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}';" -separator ' ')"
                    fi
                else
                    # ! $sqlite3
                    magnetList="$magnetList ${magnetArray[n]}"
                    echo ${magnetArray[n]} ${nameArray[n]} >> $outputFile
                fi
            fi
        done
        unset -v magnetArray nameArray
    done

    if [[ $sqlite3 ]]; then
        if [ -n "$magnetList" ]; then
            echo "검색 결과: 마그넷 ${magnetCount}개 발견"
            magnetAdd $magnetList
        fi
    else
        magnetListAdd $magnetList
        magnetNameListAdd $outputFile
        rm $outputFile
    fi
    rm $htmlFile
    #/usr/local/torrent/torrent_telegram.sh "$telegramMsgText"
}

function torrentCategory_kim() {
    # torrentCategory_kim count pageNum quality
    local count=$defaultTorrentCount
    local pageNumStart=1
    local pageNumEnd=2
    local quality="${defaultTorrentQuality}p-NEXT"
    local search="${defaultTorrentQuality}p-NEXT"

    case $1 in
        ent)    local urlType=${urlKim[0]} ;;
        drama)    local urlType=${urlKim[1]} ;;
        social)    local urlType=${urlKim[2]} ;;
        *)        return 1;;
    esac

    shift
    local var=$1
    if ((var > 0)) 2> /dev/null; then
        count=$1; shift
        var=$1
        if ((var > 0)) 2> /dev/null; then
            pageNumEnd=$1; shift
            var=$1
            if ((var > 0)) 2> /dev/null; then
                search="${1}p-NEXT"; shift
            fi
        fi
    fi

    local htmlFile=$(mktemp -q -t $(basename $0)_html.XXXXX)
    [[ $sqlite3 ]] || local outputFile=$(mktemp -q -t $(basename $0)_list.XXXXX)

    local magnetCount=0
    local magnetList
    local telegramMsgText
    for pageNum in $(seq $pageNumEnd -1 $pageNumStart); do
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
            if [[ $urlRet ]]; then
                matchCount=$(($matchCount + 1))
                ((matchCount > count)) && break
                magnetArray[n]=$(echo ${magnetArray[n]}|tr '[:upper:]' '[:lower:]')
                nameArray[n]=$(getTargetName ${nameArray[n]}|sed -e's/.mp4//' -e's/.mkv//' -e's/.avi//' -e's/.720p.*$//')
                if [[ $sqlite3 ]]; then
                    local result=$($sqlite3 "SELECT COUNT(*),name FROM magnetList WHERE magnet == '${magnetArray[n]}'")
                    local resultCount=$(echo $result|cut -d'|' -f1)
                    local resultName=$(echo $result|cut -d'|' -f2-)
                    if [[ $resultCount > 0 && $resultName == "" ]]; then
                        $sqlite3 "UPDATE magnetList SET name = '${nameArray[n]}' WHERE magnet == '${magnetArray[n]}' AND name IS NULL"
                        telegramMsgText="${telegramMsgText}#${nameArray[n]}\\n"
                    elif [[ $resultCount == 0 ]]; then
                        if $sqlite3 "INSERT INTO magnetList VALUES('${magnetArray[n]}', strftime('%s','now'), '${nameArray[n]}')"; then
                            let magnetCount=magnetCount+1
                            magnetList="$magnetList -a ${magnetArray[n]}"
                            telegramMsgText="${telegramMsgText}+${nameArray[n]}\\n"
                            echo "+[${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}'" -separator ' ')"
                        fi
                    elif [[ $forcedDownloadMode ]]; then
                        let magnetCount=magnetCount+1
                        magnetList="$magnetList -a ${magnetArray[n]}"
                        echo "![${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}';" -separator ' ')"
                    else
                        echo "@[${magnetArray[n]}] $($sqlite3 "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList WHERE magnet == '${magnetArray[n]}';" -separator ' ')"
                    fi
                else
                    # ! $sqlite3
                    magnetList="$magnetList ${magnetArray[n]}"
                    echo ${magnetArray[n]} ${nameArray[n]} >> $outputFile
                fi
            fi
        done
        unset -v magnetArray nameArray
    done

    if [[ $sqlite3 ]]; then
        if [ -n "$magnetList" ]; then
            echo "검색 결과: 마그넷 ${magnetCount}개 발견"
            magnetAdd $magnetList
        fi
    else
        magnetListAdd $magnetList
        magnetNameListAdd $outputFile
        rm $outputFile
    fi
    rm $htmlFile
    #/usr/local/torrent/torrent_telegram.sh "$telegramMsgText"
}

function magnetNameListAdd() {
    local magnetNameFile=$1
    local magnetNameCount=0
    local magnetNameListDateFile="${magnetNameListFile}_$(date +%y%m)"
    echo $magnetNameListDateFile
    while read magnet name; do
        if [ "$magnet" ]; then
            magnet=$(echo ${magnet}|tr '[:upper:]' '[:lower:]')
            local magnet_exist=$magnet
            grep --ignore-case "$magnet" ${magnetNameListFile}_* > /dev/null && magnet=""
            if [ "$magnet" ]; then
                echo "$magnet $(date '+%Y.%m.%d %T') $name" | tee -a $magnetNameListDateFile | tail -n 1
                let magnetNameCount=magnetNameCount+1
                [ "$sqlite3" ] || echo +[$magnet] $name
            else
                [ "$sqlite3" ] || echo @[$magnet_exist] $name
            fi
        fi
    done < $magnetNameFile
}
