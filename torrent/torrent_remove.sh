#!/bin/bash
#
# torrent_remove.sh <changmin811@gmail.com>

uname=$(uname)

function timestamp2seconds() {
	local timestamp="$*"
	if [ "$uname" == "Darwin" ]; then
		local seconds=$(date -j -f "%Y-%m-%d %T" "${timestamp//./-}" +%s)
	else
		local seconds=$(date -d "${timestamp//./-}" +%s)
	fi
	echo $seconds
}

function seconds2timestamp() {
	local seconds="$*"
	if [ "$uname" == "Darwin" ]; then
		local timestamp=$(date -r$seconds '+%Y-%m-%d %T')
	else
		local timestamp=$(date -d@$seconds '+%Y-%m-%d %T')
	fi
	echo $timestamp
}

function removeFileOlderThanWeeksExceptWhiteList() {
	local cmd=$1
	local whiteList=$2
	local srcFolder=$3
	local baseWeeks=$4

	[ -z "$cmd" ] && cmd="echo"
	[ -z "$baseWeeks" ] && baseWeeks=12

	local oneWeekSeconds=604800
	local currentDateSeconds=$(date +%s)
	local beforeWeeksSeconds=$(($currentDateSeconds - $oneWeekSeconds * $baseWeeks))
	if [ "$uname" == "Darwin" ]; then
		local baseDate=$(date -r$beforeWeeksSeconds +%y%m%d)
	else
		local baseDate=$(date -d@$beforeWeeksSeconds +%y%m%d)
	fi
	echo base date: $baseDate

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(ls $srcFolder); do
		#echo '#'[$folder]
		[ ! -d "$folder" ] && continue
		grep "${folder// in */}" "$whiteList" &> /dev/null && continue
		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < baseDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}

function removeFileOlderThanWeeksAtBlackList() {
	local cmd=$1
	local blackList=$2
	local srcFolder=$3
	local baseWeeks=$4

	[ -z "$cmd" ] && cmd="echo"
	[ -z "$baseWeeks" ] && baseWeeks=2

	local oneWeekSeconds=604800
	local currentDateSeconds=$(date +%s)
	local beforeWeeksSeconds=$(($currentDateSeconds - $oneWeekSeconds * $baseWeeks))
	if [ "$uname" == "Darwin" ]; then
		local baseDate=$(date -r$beforeWeeksSeconds +%y%m%d)
	else
		local baseDate=$(date -d@$beforeWeeksSeconds +%y%m%d)
	fi
	echo base date: $baseDate

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(cat $blackList); do
		echo '#'[$folder]
		[ ! -d "$folder" ] && continue
		for file in $(ls $folder 2> /dev/null); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < baseDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}

function removeFileOlderThanWeeks() {
	local cmd=$1
	local srcFolder=$2
	local baseWeeks=$3

	[ -z "$cmd" ] && cmd="echo"
	[ -z "$baseWeeks" ] && baseWeeks=4

	local oneWeekSeconds=604800
	local currentDateSeconds=$(date +%s)
	local beforeWeeksSeconds=$(($currentDateSeconds - $oneWeekSeconds * $baseWeeks))
	if [ "$uname" == "Darwin" ]; then
		local baseDate=$(date -r$beforeWeeksSeconds +%y%m%d)
	else
		local baseDate=$(date -d@$beforeWeeksSeconds +%y%m%d)
	fi
	echo base date: $baseDate

	if ! cd "$srcFolder"; then
		echo cd failed to $srcFolder
		return 1;
	fi
	pwd

	IFS=$'\n'
	for folder in $(ls $srcFolder); do
		echo '#'[$folder]
		[ ! -d "$folder" ] && continue
		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 110100)) && ((fileDate < baseDate)); then
				echo "[$baseDate][$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}
