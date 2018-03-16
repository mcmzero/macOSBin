#!/bin/bash
cd ~
for n in 1 2 3; do
    [ -f EngKor${n}.zip ] || curl https://raw.githubusercontent.com/mcmZero/macOSBin/master/Dictionaries/EngKor${n}.zip --output EngKor${n}.zip
done
for n in 1 2 3; do
    unzip EngKor${n}.zip
done
rm EngKor*.zip
