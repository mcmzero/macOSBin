#!/bin/bash

cd ~
for n in 1 2 3; do
    curl https://raw.githubusercontent.com/mcmZero/macOSBin/master/Dictionaries/EngKor${n}.zip --output EngKor${n}.zip
    unzip EngKor${n}.zip
    rm EngKor${n}.zip
done
