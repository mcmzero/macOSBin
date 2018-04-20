#!/bin/bash

if [[ $(ps -ef| grep MACafpackage | wc | awk '{print $1}') -ge 2 ]]; then
	killall -9 MACafpackage
	[[ $(ps -ef| grep MACafstreamer | wc | awk '{print $1}') -ge 2 ]] && killall -9 MACafstreamer
    echo turn off afrecca agent
else
    open -a "MACafpackage"
    echo turn on afrecca agent
fi
