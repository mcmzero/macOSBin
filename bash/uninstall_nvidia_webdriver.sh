#!/bin/sh

function uninstall() {
	sudo rm -rfv /System/Library/Extensions/Ge*Web* 
	sudo rm -rfv /System/Library/Extensions/NV*Web* \
	sudo rm -rfv /Library/Extensions/Ge*Web* \
	sudo rm -rfv /Library/Extensions/NV*Web* \
	sudo rm -rfv "/Library/PreferencePanes/NVIDIA Driver Manager.prefPane"
}

function check() {
        sudo ls -ld /System/Library/Extensions/Ge*Web* \
                /System/Library/Extensions/NV*Web* \
                /Library/Extensions/Ge*Web* \
                /Library/Extensions/NV*Web* \
                "/Library/PreferencePanes/NVIDIA Driver Manager.prefPane"
}

uninstall
echo "============="
check
