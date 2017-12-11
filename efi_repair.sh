#!/bin/sh

echo 참고용 디스크 disk0
sudo gpt show -l disk0 && diskutil list disk0

echo 복구해야될 디스크 disk1
sudo gpt show -l disk1 && diskutil list disk1
echo sudo gpt add -b 40 -i 1 -s 409600 -t efi disk1

echo 혹시 안되면 시도 해볼것
echo sudo gpt recover disk1

# EFI 파티션 복제
echo dd if=/dev/disk0s1 of=/dev/disk1s1 bs=1m 
