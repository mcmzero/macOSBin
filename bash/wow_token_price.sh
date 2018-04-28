#!/bin/bash

uname=$(uname)
if [[ $uname == "Darwin" ]]; then
    date_seconds="-r"
else
    date_seconds="-d@"
fi

function wowTokenCurrentPrice() {
	jq . <(curl -s "https://kr.api.battle.net/data/wow/token/?namespace=dynamic-kr&locale=ko_KR&access_token=cr5na62qkm64vgk5c5w28nyg")
}

function telegramMsg() {
	local tgCli="/snap/bin/telegram-cli"
	local profile="$1"; shift
	local peerId="$1"; shift
	local msgText="$*"
	$tgCli -p $profile -D -W -e "msg $peerId \"$msgText\"" > /dev/null
}

function wowTokenPrice() {
		korea=$(wowTokenCurrentPrice)
		if [[ $korea ]]; then
			price=$(jq .price <(echo $korea))
			price=$((price / 10000))
			local msgPrice="$((price/10000)).$(((price%10000)/1000))"
			echo "$(date ${date_seconds}$(($(jq .last_updated_timestamp <(echo $korea)) / 1000 ))) $msgPrice"
		fi
}

wowTokenPrice
