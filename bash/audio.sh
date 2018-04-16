#!/bin/bash

audioDevices=("USB Advanced Audio Device" "Built-in Output" "통합 출력")

function resetMic() {
    /usr/bin/osascript -e "set volume input volume (1)"
    echo $(SwitchAudioSource -c -t input) "(Input):" $(/usr/bin/osascript -e "input volume of (get volume settings)")
}

function resetUsbAudio() {
        local currentAudio=$(SwitchAudioSource -c -t output)
        SwitchAudioSource -s "${audioDevices[0]}" &> /dev/null
        resetAudio
        SwitchAudioSource -s "$currentAudio" &> /dev/null
        resetAudio
}

function resetAudio() {
        /usr/bin/osascript -e "set volume output volume (output volume of (get volume settings))" &> /dev/null
        echo "$(SwitchAudioSource -c -t output) (Output):" $(/usr/bin/osascript -e "output volume of (get volume settings)" 2> /dev/null)
}

function resetAudioAll() {
    for iter in ${!audioDevices[@]}; do
        SwitchAudioSource -s "${audioDevices[iter]}" &> /dev/null
        resetAudio
    done
}

resetMic
case $1 in
    -h) echo "$(basename $0) {reset|usb|bio|all}";;
    reset) resetUsbAudio;;
    usb) SwitchAudioSource -s "${audioDevices[0]}" &> /dev/null; resetAudio;;
    bio) SwitchAudioSource -s "${audioDevices[1]}" &> /dev/null; resetAudio;;
    all) resetAudioAll;;
    *) resetAudio;;
esac
