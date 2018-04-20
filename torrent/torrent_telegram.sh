#!/bin/bash

tgCli="/snap/bin/telegram-cli"
peerId="TV"
msgText="$*"

if [[ $msgText ]]; then
    #echo "$(whoami) $msgText" >> /home/pi/telegramMsgText.txt
    sudo -u pi $tgCli -p "floret" -D -W -e "msg $peerId \"$msgText\"" > /dev/null
fi
