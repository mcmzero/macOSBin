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
    if [[ -f $tgCli ]]; then
        $tgCli -p $profile -D -W -e "msg $peerId \"$msgText\"" > /dev/null
    else
        echo $tgCli -p $profile -D -W -e "msg $peerId \"$msgText\"" > /dev/null
    fi
}

function watchPrice() {
	local sleepTime=$((60 * $1))
    while true; do
        korea=$(wowTokenCurrentPrice)
        if [[ $korea && $koreaLast ]]; then
            price=$(jq .price <(echo $korea))
            price=$((price / 10000))
            priceLast=$(jq .price <(echo $koreaLast))
            priceLast=$((priceLast / 10000))
            priceChange=$((price - priceLast))
            if [[ $priceChange -ne 0 ]]; then
                local msgPrice="$((price/10000)).$(((price%10000)/1000))"
                [[ $koreaLast ]] && local msgPrice="$msgPrice $priceChange"
                if [[ $((price/10000)) -lt 38 ]]; then
                    telegramMsg "floret" "Token_Low" $msgPrice &
                else
                    telegramMsg "changmin" "Token" $msgPrice &
                fi
                echo "$(date ${date_seconds}$(($(jq .last_updated_timestamp <(echo $korea)) / 1000 ))) $msgPrice"
            fi
        fi
        koreaLast=$korea
        sleep $sleepTime
    done
}

clear
watchPrice 1
