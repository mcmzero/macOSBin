#!/bin/bash

declare -a mcm_rules_json=(\
	"mcm_rules_etc.json"\
	"mcm_rules_function_keys.json"\
	"mcm_rules_keypad_keys.json"\
)
comp_mod="karabiner/assets/complex_modifications"
master="https://raw.githubusercontent.com/mcmZero/macOSBin/master"

for json in ${mcm_rules_json[@]}; do
	echo $json
	curl -s "${master}/${comp_mod}/${json}" -o ~/.config/${comp_mod}/${json}
done
