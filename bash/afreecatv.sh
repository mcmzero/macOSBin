#!/bin/bash

if [[ $(ps -ef| grep MACafpackage | wc | awk '{print $1}') -ge 2 ]]; then
	killall -9 MACafpackage
	[[ $(ps -ef| grep MACafstreamer | wc | awk '{print $1}') -ge 2 ]] && killall -9 MACafstreamer
    echo Turn off AfreccaTV agent
else
    open -a "MACafpackage"
    echo Turn on AfreccaTV agent
fi
