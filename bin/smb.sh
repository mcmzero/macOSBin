#!/bin/sh

svn revert /Users/changmin/GitHub/CloverGrowerPro/edk2/Clover/rEFIt_UEFI/Platform/smbios.c
sed -i -e '811 i\
	newSmbiosTable.Type4->ExternalClock = 25;\
' /Users/changmin/GitHub/CloverGrowerPro/edk2/Clover/rEFIt_UEFI/Platform/smbios.c

open /Users/changmin/GitHub/CloverGrowerPro/edk2/Clover/rEFIt_UEFI/Platform/smbios.c
