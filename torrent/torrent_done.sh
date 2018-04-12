#!/bin/bash

if [ -f "/usr/bin/flock" ]; then
	flock -n /var/lock/torrent.lock /usr/local/torrent/torrent.sh purge
	flock -n /var/lock/torrent.lock /usr/local/torrent/torrent.sh dispose
else
	/usr/local/torrent/torrent.sh purge
	/usr/local/torrent/torrent.sh dispose
fi
