#!/bin/bash
# torrent_remove.sh <changmin811@gmail.com>

function removeFileOlderThanDateWhiteList() {
	local cmd=$1
	local whiteList=$2
	local srcFolder=$3
	local cutDate=$4
	local oneMonth=2629743

	if [ -z "$cutDate" ]; then
		# 삭제 기준일이 없으면 3개월 이전 파일을 삭제한다
		local current=$(date +%s)
		local beforeThreeMonths=$(($current - $oneMonth * 3))
		if [ "$(uname)" == "Darwin" ]; then
			cutDaet=$(date -r$beforeThreeMonths +%y%m%d)
		else
			cutDate=$(date -d@$beforeThreeMonths +%y%m%d)
		fi
		echo cut date: $cutDate
	fi

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(ls $srcFolder); do
		if [ ! -d "$folder" ]; then
			continue;
		fi

		if grep "${folder// in */}" "$whiteList" &> /dev/null; then
			echo '#'[$folder]
			continue
		fi

		echo '#'[$folder]
		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < cutDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}

function removeFileOlderThanDateBlackList() {
	local cmd=$1
	local blackList=$2
	local srcFolder=$3
	local cutDate=$4
	local oneWeek=604800

	if [ -z "$cutDate" ]; then
		# 삭제 기준일이 없으면 2주전 파일을 삭제한다
		local current=$(date +%s)
		local beforeTwoWeeks=$(($current - $oneWeek * 2))
		if [ "$(uname)" == "Darwin" ]; then
			cutDaet=$(date -r$beforeTwoWeeks +%y%m%d)
		else
			cutDate=$(date -d@$beforeTwoWeeks +%y%m%d)
		fi
		echo cut date: $cutDate
	fi

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(cat $blackList); do
		echo '#'[$folder]
		for file in $(ls $folder 2> /dev/null); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < cutDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}

function removeFileOlderThanDate() {
	local cmd=$1
	local srcFolder=$2
	local cutDate=$3
	local oneWeek=604800

	if [ -z "$cutDate" ]; then
		# 삭제 기준일이 없으면 2주전 파일을 삭제한다
		local current=$(date +%s)
		local beforeTwoWeeks=$(($current - $oneWeek * 2))
		if [ "$(uname)" == "Darwin" ]; then
			cutDaet=$(date -r$beforeTwoWeeks +%y%m%d)
		else
			cutDate=$(date -d@$beforeTwoWeeks +%y%m%d)
		fi
		echo cut date: $cutDate
	fi

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(ls $srcFolder); do
		if [ ! -d "$folder" ]; then
			continue;
		fi
		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < cutDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}
