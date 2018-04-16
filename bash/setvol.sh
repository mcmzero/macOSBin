#!/bin/bash

if [ -z "$1" ]; then
	/usr/bin/osascript -e "set volume output volume (output volume of (get volume settings))"
else
	/usr/bin/osascript \
	-e "on run(argv)" \
	-e "return set volume output volume(argv)" \
	-e "end" \
	-- "$1"
fi
