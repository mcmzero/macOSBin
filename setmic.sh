#!/bin/bash

if [ "$1" == "" ]; then
	/usr/bin/osascript -e "set volume input volume (1)"
else
	/usr/bin/osascript \
	-e "on run(argv)" \
	-e "return set volume input volume(argv)" \
	-e "end" \
	-- "$1"
fi
