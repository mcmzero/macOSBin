#!/bin/bash

ARCHIVES=/Users/changmin/Archives.localized/macOS/kexts
LE=/Library/Extensions

if [ -d "$ARCHIVES" ]; then
	sudo cp -a $ARCHIVES/FakePCIID_BCM57XX_as_BCM57765.kext $ARCHIVES/FakePCIID_XHCIMux.kext $ARCHIVES/FakePCIID.kext $LE
	sudo chown -R root:wheel $LE/FakePCIID*.kext
	sudo chmod 755 $LE/FakePCIID*.kext
	sudo kextcache -Boot -i /
fi
