#!/bin/bash

cd '/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases'
sqlite3 com.plexapp.plugins.library.db "PRAGMA integrity_check"
