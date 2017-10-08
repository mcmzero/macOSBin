#!/bin/sh
#sudo vi /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
sudo sed -e 's/>17....</>17</' -i '' /Library/Extensions/NVDAStartupWeb.kext/Contents/Info.plist
sudo chown -R root:wheel /Library/Extensions/NVDAStartupWeb.kext
sudo kextcache -i /
