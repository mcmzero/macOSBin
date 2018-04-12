#!/bin/bash

for fieldIdx in {1..6}; do
	echo "387.10.10.10.30.103"|cut -d'.' -f${fieldIdx}-
done

lastIdx=6
for ((fieldIdx = 2; fieldIdx <= $lastIdx; fieldIdx++)); do
	echo "387.10.10.10.30.103"|cut -d'.' -f${fieldIdx}-
done

for fieldIdx in $(eval echo {2..$lastIdx}); do
	echo "387.10.10.10.30.103"|cut -d'.' -f${fieldIdx}-
done

