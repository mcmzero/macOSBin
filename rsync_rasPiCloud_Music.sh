#!/bin/bash

#/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -rlv --delete --exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt" "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "/Share/rasPiCloud/음악"/
#/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -rlv --delete --exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt" "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "/Volume/rasPiCloud/share/음악"/

/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -av --delete --exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt" "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "pi@r1:/mnt/rasPiCloud/share/음악"/
