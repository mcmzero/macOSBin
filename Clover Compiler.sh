#!/bin/bash
# Script for Clover Compiler Script
# Created by Deepak on v1.0
# Copyright © 2015 Deepak insanelydeepak.wordpress.com. All rights reserved.

echo "--------------------------------------------------------------------------------"
echo "Clover Compiler Script Copyright © 2015 Deepak insanelydeepak.wordpress.com. All rights reserved."
echo "--------------------------------------------------------------------------------"
echo "==============================================="
echo "Start - Clover Compiler Script"
echo "*********************************"
echo "-----------------------------------------------"
echo ""
cd ~;
mkdir src;
cd ~/src/;
echo "=================";
echo "Downloading EDK2";
echo "=================";
svn co svn://svn.code.sf.net/p/edk2/code/trunk/edk2 ~/src/edk2;
cd ~ / src / edk2;
echo "=================";
echo "Downloading Clover";
echo "=================";
svn checkout svn://svn.code.sf.net/p/cloverefiboot/code/ ~/src/edk2/Clover;
echo "=================";
echo "Copy Files";
echo "=================";
cp ~/src/HFSPlus.efi ~/src/edk2/Clover/HFSPlus/Ia32/HFSPlus.efi;
cp ~/src/HFSPlus64.efi ~/src/edk2/Clover/HFSPlus/X64/HFSPlus.efi;
cp ~/src/edk2/Clover/Patches_for_EDK2/Conf/build_rule.txt ~/src/edk2/Conf/;
cp ~/src/edk2/Clover/Patches_for_EDK2/Conf/tools_def.txt ~/src/edk2/Conf/;
cp ~/src/edk2/Clover/Patches_for_EDK2/BaseTools/Source/Python/AutoGen/GenC.py ~/src/edk2/BaseTools/Source/Python/AutoGen;
cp ~/src/edk2/Clover/Patches_for_EDK2/MdePkg/Include/Base.h ~/src/edk2/MdePkg/Include;
echo "=================";
echo "building GCC";
echo "=================";
cd ~/src/edk2/Clover/;
./buildgcc-4.9.sh;
./buildnasm.sh;
./buildgettext.sh;
echo "=================";
echo "building Clover x64";
echo "=================";
cd ~/src/edk2/Clover/;
./ebuild.sh -x64;
echo "=================";
echo "building Clover boot7";
echo "=================";
./ebuild.sh -mc;
echo "=================";
echo "building Clover ia32";
echo "=================";
./ebuild.sh --ia32;
echo "=================";
echo "building CloverPKG";
echo "=================";
cd ~/src/edk2/Clover/CloverPackage/;
./makepkg;
echo "=================";
echo "building CloverISO";
echo "=================";
cd ~/src/edk2/Clover/CloverPackage/;
./makeiso;
echo "==============================================="
echo "END - Clover Compiler Script "
echo "*********************************"
echo "-----------------------------------------------"
echo ""
