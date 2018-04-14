#!/bin/sh

cat <<EOF | ssdtPRGen.sh && cp -v /Users/changmin/Library/ssdtPRGen/ssdt.aml /Volumes/ESP/EFI/CLOVER/ACPI/patched/SSDT.aml
n
n
EOF
