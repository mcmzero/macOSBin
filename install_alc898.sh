#!/bin/sh

cd /Volumes/Drive/Google\ Drive/OS\ X/Kexts 
cp -a realtekALC.kext /Volumes/EFI/EFI/CLOVER/kexts/10.10
cp *.zml.zlib /System/Library/Extensions/AppleHDA.kext/Contents/Resources/
chmod 755 /System/Library/Extensions/AppleHDA.kext/Contents/Resources/*.zml.zlib
chown root:wheel /System/Library/Extensions/AppleHDA.kext/Contents/Resources/*.zml.zlib
