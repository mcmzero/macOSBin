#!/bin/bash

get_1000() {
for (( c=1000; c<=2174; c++ ))
do
	wget https://air21.daum.net/images/sticker/high/sticker_${c}.png
done
}

get_100() {
for (( c=100; c<=999; c++ ))
do
	wget https://air21.daum.net/images/sticker/high/sticker_${c}.png
done
}

get_10() {
for (( c=10; c<=99; c++ ))
do
	wget https://air21.daum.net/images/sticker/high/sticker_0${c}.png
done
}

get_1() {
for (( c=0; c<=9; c++ ))
do
	wget https://air21.daum.net/images/sticker/high/sticker_00${c}.png
done
}

get_1 &
get_10 &
get_100 &
get_1000 &
