#!/bin/bash
#
# torrent.sh <changmin811@gmail.com>

defaultQuality=720
defaultCount=100

magnetListFile="/usr/local/torrent/magnet_list"
whiteListFile="/usr/local/torrent/torrent_whitelist.txt"
blackListFile="/usr/local/torrent/torrent_blacklist.txt"
torrentFile="/usr/local/torrent/torrent.sh"
downloadFile="/usr/local/torrent/torrent_download.sh"
disposeFile="/usr/local/torrent/torrent_dispose.sh"
removeFile="/usr/local/torrent/torrent_remove.sh"
excludeFile="/usr/local/torrent/rsync_exclude_pattern.txt"
backupFile="$HOME/bin/bash/backup_rsync.sh"

source $downloadFile
programName=$(basename $0)
if [ "$(echo $programName | cut -d_ -f 1)" == "local" ]; then
	setServerLocal
else
	setServerConfig
fi

function runHelp() {
	#torrentSearch count page_max_num quality(360 720 1080) search text
	echo "사용법:"
	echo "$programName cor 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName kim 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName pon 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo
	echo "$programName cor ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "$programName kim ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "$programName pon ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo
	echo "$programName ent pagenum"
	echo "$programName drama pagenum"
	echo "$programName social pagenum"
	echo
	echo "$programName 사이트(cor kim pong) ent pagenum"
	echo "$programName 사이트(cor kim pong) drama pagenum"
	echo "$programName 사이트(cor kim pong) social pagenum"
	echo
	echo "$programName 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName 개수 시작페이지 최대페이지 화질(360 720 1080)"
	echo "$programName 개수 시작페이지 최대페이지 검색어"
	echo "$programName 개수 시작페이지 검색어"
	echo "$programName 개수 검색어"
	echo "$programName 검색어"
	echo
	echo "예제:"
	echo "$programName 100 5 720 동상이몽2"
	echo "$programName 1 1 360 TV소설 꽃피어라 달순아"
	echo "$programName 1 1 720 황금빛 내 인생"
	echo "$programName 1 1 720 무한 도전"
	echo "$programName 100 2 720 아는 형님"
	echo
	echo "$programName cor ep 1 12 720 개그 콘서트"
	echo "$programName kim ep 1 12 360 맛있는 녀석들"
	echo "$programName pong ep 1 12 1080 맛있는 녀석들"
	echo
}

function runSync() {
	echo rsync rasPi

	local optVerbose="-v"
	local srcPath="$HOME/Developer.localized/ShellScript.localized/TorrentBin"
	local trgPath="/usr/local/torrent"

	#backup rasPi1 /etc
	rsync -aCz --no-g --no-o -e ssh\
		root@rpi:/etc/samba/smb.conf\
		$HOME/Archives.localized/raspberryPi/etc/samba/smb.conf
	rsync -aCz --no-g --no-o -e ssh\
		root@rpi:/etc/transmission-daemon/settings.json\
		$HOME/Archives.localized/raspberryPi/etc/transmission-daemon/settings.json

	# /etc/cron.d/torrent_cron_ras
	rsync -auz --no-g --no-o -e ssh\
		--exclude-from=${excludeFile}\
		"$srcPath/torrent_cron_"* "root@rpi:/etc/cron.d/"
	rsync -auz --no-g --no-o -e ssh\
		--exclude-from=${excludeFile}\
		"root@rpi:/etc/cron.d/torrent_cron_"* "$srcPath/"

	# Torrentbin to /usr/local/torrent
	rsync -aCz --no-g --no-o -e ssh\
		--exclude-from=${excludeFile}\
		"$srcPath/" "pi@rpi:$trgPath"
	rsync -aCz --no-g --no-o --delete -e ssh\
		--exclude-from=${excludeFile}\
		"$srcPath/" "pi@rpi:tor"
	rsync -aCz --no-g --no-o --delete\
		--exclude-from=${excludeFile}\
		"$srcPath/" "$trgPath"
	rsync -aCz --no-g --no-o --delete\
		--exclude-from=${excludeFile}\
		"$srcPath/" "$HOME/bin/torrent"
	# convert text format from UTF8-MAC to UTF8
	local srcWhiteListFile="$srcPath/$(basename $whiteListFile)"
	local srcBlackListFile="$srcPath/$(basename $blackListFile)"
	if [ -f "$srcWhiteListFile" ]; then
		local tempWhiteFile="$(mktemp -q -t $(basename $0).white.XXX)"
		local tempBlackFile="$(mktemp -q -t $(basename $0).black.XXX)"
		iconv -f UTF8-MAC -t UTF8 "$srcWhiteListFile" > "$tempWhiteFile"
		iconv -f UTF8-MAC -t UTF8 "$srcBlackListFile" > "$tempBlackFile"
		mv -f "$tempWhiteFile" "$srcWhiteListFile"
		mv -f "$tempBlackFile" "$srcBlackListFile"
		#rsync listfile
		rsync -aCz --no-g --no-o -e ssh\
			--exclude-from=${excludeFile}\
			"$srcPath/" "pi@rpi:$trgPath"
		rsync -aCz --no-g --no-o --delete -e ssh\
			--exclude-from=${excludeFile}\
			"$srcPath/" "pi@rpi:tor"
		rsync -aCz --no-g --no-o --delete\
			--exclude-from=${excludeFile}\
			"$srcPath/" "$trgPath"
		rsync -aCz --no-g --no-o --delete\
			--exclude-from=${excludeFile}\
			"$srcPath/" "$HOME/bin/torrent"
	fi

	# /usr/local/torrent/magnet.db
	rsync -aCz --no-g --no-o -e ssh\
		--exclude-from=${excludeFile}\
		"pi@rpi:$trgPath/magnet"* "$trgPath/"
}

function linkFile() {
	for file in $(ls -1 /usr/local/torrent/t*.sh); do
		file=${file//local_//}
		sudo ln -sfv $file /usr/local/bin/$(basename $file)
	done
}

function torrentSite() {
	local pageNumber=1
	local site=$1
	shift
	case $1 in
		login)
			torrentLogin_$site
		;;
		ent|drama|social)
			[ $# -eq 2 ] && pageNumber=$2
			torrentCategory_$site $1 $defaultCount $pageNumber $DEFAULT_QUALITY
		;;
		ep)
			shift
			local epStart=$1
			shift
			local epEnd=$1
			shift
			local epQuality=$1
			shift
			local epName="$*"
			for epNumber in $(seq $epStart $epEnd); do
				torrentSearch_$site 1 1 1 "${epQuality}" "${epName}.E${epNumber}."
				torrentSearch_$site 1 1 1 "${epQuality}" "${epName}.E0${epNumber}."
			done
		;;
		*)
			torrentSearch_$site "$@"
		;;
	esac
}

function runCommand() {
	case $1 in
		runSync)
			shift
			runSync $@
		;;
		sync)
			shift
			if [ "$(hostname -s)" == "rasPi" ]; then
				ssh changmin@192.168.0.8 $torrentFile runSync
			else
				runSync $@
				source $backupFile
			fi
		;;
		backup)
			source $backupFile
		;;
		link)
			linkFile
		;;
		clean)
			find . \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rfv {} \;
		;;
		synclink)
			linkFile
			ssh root@rpi $torrentFile link
		;;
		localized)
			for file in *; do
				[ -d "$file" ] && rsync -az ~changmin/Documents/.localized ./"$file"/
			done
		;;
		purge)
			shift
			torrentPurge $@
		;;
		cleanup)
			source $disposeFile
			cleanupRasPi
		;;
		dispose)
			shift
			source $disposeFile
			disposeTorrent $@
			return 0
		;;
		magnet*)
			magnetAdd -a $@
            /usr/local/torrent/torrent_telegram.sh "$*"
            exit $?
		;;
		*)
			return 1;
		;;
	esac
}

function run() {
	case $1 in
		db)
			cd '/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases'
			sqlite3 com.plexapp.plugins.library.db "PRAGMA integrity_check"
		;;
		remove)
			run rmdefault
			run rmwlist
			run rmblist
		;;
		rmdefault)
			shift
			source $removeFile
			source $disposeFile
			removeFileOlderThanWeeks rm "${rasPiPathArray[0]}" 4
			removeFileOlderThanWeeks rm "${rasPiPathArray[1]}" 4
			removeFileOlderThanWeeks rm "${rasPiPathArray[2]}" 4
			removeFileOlderThanWeeks rm "${rasPiPathArray[rasPiPathArrayEndIndex]}" 8
			df -h /mnt/rasPiTorrent
		;;
		rmwlist)
			shift
			source $removeFile
			source $disposeFile
			for n in ${!rasPiPathArray[@]}; do
				removeFileOlderThanWeeksExceptWhiteList rm "$whiteListFile" "${rasPiPathArray[n]}" $@
			done
			df -h /mnt/rasPiTorrent
		;;
		white|wlist)
			shift
			source $removeFile
			source $disposeFile
			for n in ${!rasPiPathArray[@]}; do
				removeFileOlderThanWeeksExceptWhiteList echo "$whiteListFile" "${rasPiPathArray[n]}" $@
			done
			df -h /mnt/rasPiTorrent
		;;
		rmblist)
			shift
			source $removeFile
			source $disposeFile
			for n in ${!rasPiPathArray[@]}; do
				removeFileOlderThanWeeksAtBlackList rm "$blackListFile" "${rasPiPathArray[n]}" $@
			done
			df -h /mnt/rasPiTorrent
		;;
		black|blist)
			shift
			source $removeFile
			source $disposeFile
			for n in ${!rasPiPathArray[@]}; do
				removeFileOlderThanWeeksAtBlackList echo "$blackListFile" "${rasPiPathArray[n]}" $@
			done
			df -h /mnt/rasPiTorrent
		;;
		trans*|-t)
			shift
			transDefault $@
		;;
		list|-l)
			transDefault -l|grep -ve'ID.*Name' -ve'Sum:.*'
		;;
		ls*|ta*)
			if [ "$(hostname -s)" == "rasPi" ]; then
				#tail ${magnetListFile}_* | tail
				sqlite3 /usr/local/torrent/magnet.db "SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList ORDER BY time DESC  LIMIT 15;" -separator ' '
			else
				#ssh pi@rpi "tail ${magnetListFile}_* | tail"
				ssh pi@rpi "sqlite3 /usr/local/torrent/magnet.db \"SELECT datetime(time, 'unixepoch', 'localtime'), name FROM magnetList ORDER BY time DESC  LIMIT 15;\" -separator ' '"
			fi
		;;
		kim|cor|pon)
			torrentSite $@
		;;
		drama|ent|social|ep)
			torrentSite cor $@
			torrentSite pon $@
			torrentSite kim $@
		;;
		login)
			torrentLogin_cor
			torrentLogin_pon
			torrentLogin_kim
		;;
		-h)
			runHelp
		;;
		*)
			if [ $# -eq 0 ]; then
				runHelp
				return $?
			fi
			if runCommand $@; then
				return $?
			fi
			if torrentSearch $@; then
				return $?
			fi
		;;
	esac
}

run $@
