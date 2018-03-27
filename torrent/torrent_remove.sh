#!/bin/bash
# torrent_remove.sh <changmin811@gmail.com>

function removeFileOlderThanDate() {
	local whiteList=$1
	local srcFolder=$2
	local cutDate=$3

	if [ "$cutDate" == "" ]; then
		# 삭제 기준일이 없으면 3개월 이전 파일을 삭제한다
		local current=$(date +%s)
		local before3month=$(($current - 3 * 2629743))
		if [ "$(uname)" == "Darwin" ]; then
			cutDaet=$(date -r$before3month +%y%m%d)
		else
			cutDate=$(date -d@$before3month +%y%m%d)
		fi
		echo cut date: $cutDate
	fi

	IFS=$'\n'
	cd "$srcFolder"
	for folder in $(ls $srcFolder); do
		if [ ! -d "$folder" ]; then
			continue;
		fi

		if grep "$folder" "$whiteList" &> /dev/null; then
			continue
		fi

		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 170100)) && ((fileDate < cutDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				rm -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}
