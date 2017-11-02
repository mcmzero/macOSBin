#!/bin/sh

#echo $line | cut -f 2

while read A B
do
echo "KKK $B SSS"
echo "enable = 1"
echo "schedule = 0000000 0000 0000"
echo "flag = 0"
echo "{"
echo "	direction = inout"
echo "	src_type = ip"
echo "	url = $B"
echo "	policy = drop"
echo "}"
done < $1
