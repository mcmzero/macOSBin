#!/bin/bash

sleep 3
if [ -f "/usr/bin/flock" ]; then
    flock -n /var/lock/torrent.lock /usr/local/torrent/torrent.sh dispose
else
    /usr/local/torrent/torrent.sh dispose
fi
