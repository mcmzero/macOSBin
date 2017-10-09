#!/bin/sh

sudo cp -avf /Volumes/ESP/EFI/CLOVER/kexts/Other/CodecCommander.kext /System/Library/Extensions/
sudo chmod -R 755 /Volumes/ESP/EFI/CLOVER/kexts/Other/CodecCommander.kext
sudo chown -R root:wheel /Volumes/ESP/EFI/CLOVER/kexts/Other/CodecCommander.kext
kextcache -i /
