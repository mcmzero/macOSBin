#!/bin/bash

PKG_FILE=$(ls lineage*d802*.zip)
UPDATER_SCRIPT="META-INF/com/google/android/updater-script"
if [ "$PKG_FILE" == "" ]; then
    exit
fi

unzip $PKG_FILE $UPDATER_SCRIPT
sed -e "s/d802/f320/g" -i '' $UPDATER_SCRIPT
zip -u $PKG_FILE $UPDATER_SCRIPT
rm -rf META-INF

mv $PKG_FILE "/Users/changmin/Seafile/내 라이브러리/Android/LG G2 F320S/"