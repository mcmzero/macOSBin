#!/bin/bash

tgCli="/snap/bin/telegram-cli"
peerId="토렌트"
msgText="$*"

if [[ $1 ]]; then
	$tgCli -D -W -e "msg $peerId \"$msgText\"" > /dev/null
fi
