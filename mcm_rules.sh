#!/bin/bash

function mcm_zip() {
	# -j remove path info
	rm ~/Downloads/mcm_rules.zip
	zip -j ~/Downloads/mcm_rules.zip ~/.config/karabiner/assets/complex_modifications/mcm_rules*.json
}

function mcm_unzip() {
	# -o overwrite -d change directory
	unzip -o ~/Downloads/mcm_rules.zip -d ~/.config/karabiner/assets/complex_modifications
}

function mcm_list() {
	# -l list
	unzip -l ~/Downloads/mcm_rules.zip
}

case $1 in 
-h)
	echo $(basename $0) '{zip|unzip|list}'
;;
zip)
	mcm_zip
;;
unzip)
	mcm_unzip
;;
list)
	mcm_list
;;
*)
	mcm_zip
	mcm_list
;;
esac
