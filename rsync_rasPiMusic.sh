#!/bin/bash

#/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -rlv --delete "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "/Share/rasPiMusic/음악"/
#/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -rlv --delete "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "/Volume/rasPiMusic/torrent/음악"/

/usr/local/bin/rsync --iconv=utf-8-mac,utf-8 -rlv --delete "/Users/changmin/Music/iTunes/iTunes Media/Music"/ "pi@r1:/mnt/rasPiMusic/torrent/음악"/
