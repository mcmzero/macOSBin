#!/bin/bash

source /usr/local/bin/download_torrent.sh
[ "$(basename $0 | cut -d_ -f 1)" == "local" ] && set_server_local || set_server_config

purge_torrent $@
