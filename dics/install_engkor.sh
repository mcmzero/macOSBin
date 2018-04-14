#!/bin/bash
cd ~
for n in {1..3}; do
    [ -f EngKor${n}.zip ] || curl https://raw.githubusercontent.com/mcmZero/macOSBin/master/dics/EngKor${n}.zip --output EngKor${n}.zip
done
for n in {1..3}; do
    unzip EngKor${n}.zip
done
rm EngKor*.zip
