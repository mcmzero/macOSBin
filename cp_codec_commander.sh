#!/bin/sh

sudo cp -avf /Volumes/ESP/EFI/CLOVER/kexts/Other/CodecCommander.kext /System/Library/Extensions/

sudo chmod -R 755 /System/Library/Extensions/CodecCommander.kext
sudo chown -R root:wheel /System/Library/Extensions/CodecCommander.kext

kextcache -i /
