#!/bin/sh

find /Applications ~/Applications -maxdepth 3 -name "*.app" | while read a ; do echo; echo -n "$a ___ "; codesign -vd "${a}" 2>&1 | awk '/version/ {print $3}'; done | awk -F'___' '{print $2 " " $1}' | sort -u

