#!/bin/bash

case $1 in
    rm)
        sudo rm -rf /System/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-e4f
    ;;
    cp)
        sudo cp -afv /Volumes/Backup.localized/Archives.localized/macOS/DisplayVendorID-e4f /System/Library/Displays/Contents/Resources/Overrides/
    ;;
    ls)
        ls -l /System/Library/Displays/Contents/Resources/Overrides
    ;;
esac
