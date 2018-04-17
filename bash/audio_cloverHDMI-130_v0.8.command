#!/bin/sh
# Maintained by: toleda for: github.com/toleda/audio_cloverHDMI
gFile="audio_cloverHDMI-130_v0.8.command"
# Credit: bcc9, RevoGirl, PikeRAlpha, RehabMan
#
# macOS Clover HDMI Audio
#
# Enables macOS HDMI audio in 10.8 and newer, all versions
# 1. Supports Intel integrated graphics and/or AMD and Nvidia discrete graphics
# 2. Installs HDMI audio ssdt and required framebuffer edits (Intel only)
# 3. Native CPU and GPU power management (Intel only, additonal steps required)
#
# Requirements
# 1. macOS: 10.13/10.12/10.11/10.10/10.9/10.8, all versions
# 2. Native AppleHDA.kext  (If not installed, run 10.x.x installer)
# 3. Recognized Intel/AMD/Nvidia graphics
# 4. Clover only: 1. UEFI, mount EFI partition and 2. Clover Legacy
#
# Supports:[QUOTE="izham, post: 1693760, member: 1190658"]installed just the sound driver for ALC887 current from Multibeast 5.4.3[/QUOTE]
# 1. Intel/desktop series: 200, 100, 9, 8, 7, 6, 5
#         Intel/workstation series: X299, X99, X79, X58
# 2. Intel Graphics HD:
#         Desktop: HD6x0, HD5x0, HD6200, HD4600+, HD4000, HD3000
#         BRIX/NUC: HD580, HD540, HD6100, HD6000, HD5500, HD5200, HD5000, HD4000
# 3. AMD/default framebuffer: RX 5x0/4x0, R7/R9 3xx, R7/R9 2xx, 7xxx, 6xxx, 5xxx
#         Except: GCN 1.1/Hawaii/Bonaire)
# 4. Nvidia/macOS drivers: 10xx, 9xx,  7xx, 6xx, 5xx, 4xx (except 450, 550, 560)
#         Required: Nvidia/Web drivers: 10xx, 9xx, 750
#
# Debug Mode (saves ssdt and config.plist to Desktop
# 1. Set audio_cloverHDMI-1x0.command/gDebug=1 (below)
# 2. Copy config.plist to Desktop
# 3. Continue with Installation/Step 3
#
# Installation
# 1. Double click audio_cloverHDMI...command
# 2. Enter password at prompt
# 3. Questions (answer y or n)
#    Install SSDT-HDMI-HDxxx HDMI audio ssdt (y/n)
#    Verify SSDT-HDMI-HDxxx HDMI audio connector (y/n)
#    Confirm DP to HDMI connector patch on port 0x5 (y/n)
#    Install AMD/Nvidia HDMI audio (y/n)
#    Install AMD HDMI audio ssdt (y/n)
# 4. Restart
#
# Change log
# v0.8 - 2/14/18: Add config.plist validation, option to proceed with invalid Audio ID
# v0.7 - 2/8/18: Added X299 - PC02/PCI2 ACPI devices, updated Name property
# v0.6 - 10/15/17: Fixed
# v0.5 - 10/12/17: Pulled, source control error
# v0.4 - 8/31/17: Audio ID verification
# v0.3 - 8/22/17: fix HD630 port calculation
# v0.2 - 729/17: fix HD630 device_id
# v0.1 - 7/6/17: Initial 10.13 support
#
echo " "
echo "Agreement"
echo "The audio_cloverHDMI script is for personal use only. Do not distribute"
echo "the patch, any or all of the files for any reason without permission."
echo "The audio_cloverHDMI script is provided as is and without any warranty."
echo " "

# set initial variables
# debug=0 - normal install,
# debug=1 - test drive, copy config.plist to Desktop, edited config.plist and ssdt copied to Desktop
gDebug=0

gSysVer=`sw_vers -productVersion`
gSysName="El Capitan"
gStartupDisk=EFI
gCloverDirectory=/Volumes/$gStartupDisk/EFI/CLOVER
gDesktopDirectory=/Volumes/$(whoami)/Desktop
# gDesktopDirectory=/Volumes/850E-Users/Users/$(whoami)/Desktop  ##
gssdtinstall=n
gigfxlvds=0
gideviceid=0
givendorid=0
gigfxhdmicodec=0
gigfxhdmihdau=y
gigfxportmax=7
gigfxport5=0
gigfxports=3
gigfxnuc=1
gdgfxname1=0
gdgfxssdt=0
gdgfxname=0
gdgfx=0
ghdmi=0
gAudioid=1
validaudioid=y

# Terminal commands
# ioreg -rxn IGPU@2 | grep vendor-id| awk '{ print $4 }'
# ioreg -rxn IGPU@2 | grep device-id | sed -e 's/.*<//' -e 's/>//'
# ioreg -rxn IGPU@2 | grep "AAPL,ig-platform-id"| awk '{ print $4 }'
# ioreg -rxn IGPU@2 | grep "hda-gfx"| awk '{ print $4 }'
# ioreg -rxn IGPU@2 | grep -c "hda-gfx"
# ioreg -rxn HDAU@0 | grep "hda-gfx"| awk '{ print $4 }'
# ioreg -rxn HDAU@0,1 | grep device-id| awk '{ print $4 }'
# ioreg -rxn P0P2@3 | grep vendor-id| awk '{ print $4 }'
# ioreg -rw 0 -p IODeviceTree -n IGPU@2 > /tmp/IGPU.txt
# ioreg -rw 0 -p IOService -n AppleIntelFramebuffer@0 > /tmp/IGPU.txt
# audioinfo=$(cat /tmp/IGPU.txt | grep -c "audio-codec-info")
# connector=$(cat /tmp/IGPU.txt | grep connector-type | sed -e 's/.*<//' -e 's/>//')

function _patchconfig()
{

# debug
if [ $gDebug = 2 ]; then
 echo "patch = $patch"
fi

# add patches to config.plist/KernelAndKextPatches/KextsToPatch
sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches:KextsToPatch:$patch'" /tmp/config-audio_cloverHDMI.plist -x > "/tmp/ktp.plist"
ktpcomment=$(sudo /usr/libexec/PlistBuddy -c "Print 'Comment'" "/tmp/ktp.plist")
sudo /usr/libexec/PlistBuddy -c "Set :Comment 't2-$ktpcomment'" "/tmp/ktp.plist"
sudo /usr/libexec/PlistBuddy -c "Add :KernelAndKextPatches:KextsToPatch:0 dict" /tmp/config.plist
sudo /usr/libexec/PlistBuddy -c "Merge /tmp/ktp.plist ':KernelAndKextPatches:KextsToPatch:0'" /tmp/config.plist

# exit if error
if [ "$?" != "0" ]; then
echo "Error: config.plst patch failed"
echo “Original config.plist restored”
sudo cp -X $gCloverDirectory/config-backup.plist $gCloverDirectory/config.plist
sudo rm -R /tmp/ktp.plist
sudo rm -R /tmp/config.plist
sudo rm -R /tmp/config-audio_cloverALC+.plist.zip
sudo rm -R /tmp/config-audio_cloverALC.plist
sudo rm -R /tmp/__MACOSX
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 1
fi

}

# verify system version
case ${gSysVer} in

    10.13* ) gSysName="High Sierra"
    gSysFolder=kexts/10.13
    gSID=$(csrutil status)
    ;;

    10.12* ) gSysName="Sierra"
    gSysFolder=kexts/10.12
    gSID=$(csrutil status)
    ;;

    10.11* ) gSysName="El Capitan"
    gSysFolder=kexts/10.11
    gSID=$(csrutil status)
    ;;

    10.10* ) gSysName="Yosemite"
    gSysFolder=kexts/10.10
    ;;

    10.9* ) gSysName="Mavericks"
    gSysFolder=kexts/10.9
    ;;

    10.8* ) gSysName="Mountain Lion"
    gSysFolder=kexts/10.8
    ;;

    * )
    echo "macOS Version: $gSysVer is not supported"
    echo "No system files were changed"
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
    ;;

esac

# debug
if [ $gDebug = 2 ]; then
    # gSysVer=10.9
    echo "System version: supported"
    echo "gSysVer = $gSysVer"
fi

gDebugMode[0]=Release
gDebugMode[1]=TestDrive
gDebugMode[2]=Debug

# verify Debug setting
case $gDebug in

    0|1|2 )
    ;;

    * )
    echo "gDebug = $gDebug not invalid, script terminating"
    echo "No system files were changed"
    exit 1
    ::

esac

echo "File: $gFile"
echo "${gDebugMode[$gDebug]} Mode"

# credit: mfram, http://forums.macrumors.com/showpost.php?p=18302055&postcount=6
# get startup disk name
gStartupDevice=$(mount | grep "on / " | cut -f1 -d' ')
gStartupDisk=$(mount | grep "on / " | cut -f1 -d' ' | xargs diskutil info | grep "Volume Name" | perl -an -F'/:\s+/' -e 'print "$F[1]"')

# debug
if [ $gDebug = 2 ]; then
    echo "Boot device: $gStartupDevice"
    echo "Boot volume: $gStartupDisk"
fi

# check for debug (debug=1 and 2 do not touch CLOVER folder)
case $gDebug in
0 )

# verify EFI install
gEFI=0
if [ -d $gCloverDirectory ]; then
     gEFI=1
fi

if [ $gEFI = 0 ]; then

    if [ -d '/Volumes/ESP/EFI/CLOVER' ]; then
        gCloverDirectory=/Volumes/ESP/EFI/CLOVER
        gEFI=1
    fi

fi

if [ $gEFI = 1 ]; then
    echo "EFI partition is mounted"
    if [ -f "$gCloverDirectory/config.plist" ]; then
        cp -p "$gCloverDirectory/config.plist" "/tmp/config.plist"
        if [ -f "$gCloverDirectory/config-backup.plist" ]; then
            rm -R "$gCloverDirectory/config-backup.plist"
        fi
        cp -p "$gCloverDirectory/config.plist" "$gCloverDirectory/config-backup.plist"
    else
        echo "$gCloverDirectory/config.plist is missing"
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi
else
    echo "EFI partition not mounted"

# confirm Clover Legacy install
    gCloverDirectory=/Volumes/"$gStartupDisk"/EFI/CLOVER
    if [ -d "$gCloverDirectory" ]; then
	    echo "$gStartupDisk/EFI folder found"
    else echo "$gStartupDisk/EFI not found"
	    echo "EFI/CLOVER folder not available to install HDMI audio"
	    echo "No system files were changed"
	    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
	    exit 1
    fi

# initialize variable
    choice7=n

    while true
    do
    read -p "Confirm Clover Legacy Install (y/n): " choice7
    case "$choice7" in

    [yY]* )
#    gCloverDirectory=/Volumes/"$gStartupDisk"/EFI/CLOVER
    if [ -d "$gCloverDirectory" ]; then
        if [ -f "$gCloverDirectory/config.plist" ]; then
            cp -p "$gCloverDirectory/config.plist" "/tmp/config.plist"
            if [ -f "$gCloverDirectory/config-backup.plist" ]; then
                rm -R "$gCloverDirectory/config-backup.plist"
            fi
            cp -p "$gCloverDirectory/config.plist" "$gCloverDirectory/config-backup.plist"
        else
            echo "$gCloverDirectory/config.plist is missing"
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
        fi

    else
    echo "$gCloverDirectory not found"
    echo "No system files were changed"
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
    fi

    break
    ;;

    [nN]* )
    echo "User terminated, EFI partition/folder not mounted"
    echo “Mount EFI partition and Restart“
    echo "No system files were changed"
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
    ;;

    * ) echo "Try again...";;
    esac
    done
    fi
;;

1|2 )
    if [ -f "Desktop/config.plist" ]; then
        cp -R Desktop/config.plist /tmp/config.plist
#        echo "Debug mode"
#        echo "Desktop/config.plist copied to /tmp/config.plist"
     else
        echo "Desktop/config.plist missing, Debug mode not possible"
	exit 1
    fi
;;

esac

# verify ioreg/HDEF
ioreg -rw 0 -p IODeviceTree -n HDEF > /tmp/HDEF.txt

if [[ $(cat /tmp/HDEF.txt | grep -c "HDEF@1") = 0 ]]; then
echo "Error: no IOReg/HDEF; BIOS/audio/disabled or ACPI problem"

    while true
        do
        read -p "Continue without HDEF/onboard audio (y/n): " choice0
        case "$choice0" in
            [yY]* ) break;;
            [nN]* )
                echo "No system files were changed"
                echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                rm -R /tmp/HDEF.txt
                exit 1
                ;;
            * ) echo "Try again...";;
        esac
    done
fi

# HDEF/layout-id

if [[ $(cat /tmp/HDEF.txt | grep -c "HDEF@1") != 0 ]]; then
    gLayoutidioreg=$(cat /tmp/HDEF.txt | grep layout-id | sed -e 's/.*<//' -e 's/>//')
    gLayoutidhex="0x${gLayoutidioreg:6:2}${gLayoutidioreg:4:2}${gLayoutidioreg:2:2}${gLayoutidioreg:0:2}"
    gAudioid=$((gLayoutidhex))
fi

# verify ioreg/GFX0
ioreg -rw 0 -p IODeviceTree -n GFX0@2 > /tmp/IGPU.txt
if [[ $(cat /tmp/IGPU.txt | grep -c "GFX0@2") = 0 ]]; then
    gigfx=0

# debug
    if [ $gDebug = 2 ]; then
        echo "GFX0 - gigfx = $gigfx"
    fi

# verify ioreg/IGPU
    ioreg -rw 0 -p IODeviceTree -n IGPU@2 > /tmp/IGPU.txt
    if [[ $(cat /tmp/IGPU.txt | grep -c "IGPU@2") = 0 ]]; then
        gigfx=0

# debug
        if [ $gDebug = 2 ]; then
            echo "IGPU - gigfx = $gigfx"
        fi

    else
        gigfx=IGPU@2

# debug
        if [ $gDebug = 2 ]; then
            echo "gigfx = $gigfx"
        fi

    fi

else
gigfx=GFX0@2

# debug
    if [ $gDebug = 2 ]; then
        echo "gigfx = $gigfx"
    fi

fi # found HDEF, layout-id, igfx

rm -R /tmp/IGPU.txt
rm -R /tmp/HDEF.txt

# verify config.plist/KernelAndKextPatches:KextsToPatch
ktpexisting=$(sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches'" /tmp/config.plist)

if [ -z "${ktpexisting}" ]; then
    sudo /usr/libexec/PlistBuddy -c "Add KernelAndKextPatches:KextsToPatch array" /tmp/config.plist
    echo "Edit config.plist: Add KernelAndKextPatches/KextsToPatch - Fixed"
fi

ktpexisting=$(sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches:KextsToPatch:'" /tmp/config.plist)

if [ -z "${ktpexisting}" ]; then
    sudo /usr/libexec/PlistBuddy -c "Add KernelAndKextPatches:KextsToPatch array" /tmp/config.plist
    echo "Edit config.plist: Add KextsToPatch - Fixed"
fi

# exit if error
if [ "$?" != "0" ]; then
    echo "Error: config.plist/KernelAndKextPatches/KextsToPatch fix failed"
    echo “Original config.plist restored”
    echo “Install valid config.plist”
    sudo cp -X $gCloverDirectory/config-backup.plist $gCloverDirectory/config.plist
    sudo rm -R /tmp/ktp.plist
    sudo rm -R /tmp/config.plist
    sudo rm -R /tmp/config-audio_cloverHDMI+.plist.zip
    sudo rm -R /tmp/config-audio_cloverHDMI.plist
    sudo rm -R /tmp/__MACOSX
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
fi

# get installed codecs
gCodecsInstalled=$(ioreg -rxn IOHDACodecDevice | grep VendorID | awk '{ print $4 }' | sed -e 's/ffffffff//')

# debug
if [ $gDebug = 2 ]; then
# gCodecsInstalled=0x10ec0900
# gCodecsInstalled=0x10134206
    echo "gCodecsInstalled = $gCodecsInstalled"
fi

# no audio codecs detected
if [ -z "${gCodecsInstalled}" ]; then
    echo ""
    echo "No audio codec detected"
    echo "No system files were changed"
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
fi

# initialize variables
intelhdmi=0
amdhdmi=0
nvidiahdmi=0

# find codecs
index=0
for codec in $gCodecsInstalled
do

# debug
if [ $gDebug = 2 ]; then
    echo "Index = $index, Codec = $codec"
fi

# sort vendors and devices
case ${codec:2:4} in

    8086 ) Codecintelhdmi=$codec; intelhdmi=1
    ;;
    1002 ) Codecamdhdmi=$codec; amdhdmi=1
    ;;
    10de ) Codecnvidiahdmi=$codec; nvidiahdmi=1
    ;;

esac
index=$((index + 1))
done

ghdmi=$((intelhdmi+amdhdmi+nvidiahdmi))
gdgfx=$((amdhdmi+nvidiahdmi))

# no hdmi codecs detected
if [ $ghdmi = 0 ]; then

    while true
        do
        read -p "No HDMI audio codec(s) detected, continue (y/n): " choice4
        case "$choice4" in
            [yY]* )
                gdgfx=1
                break
                ;;
            [nN]* )
                echo "No system files were changed"
                echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                rm -R /tmp/HDEF.txt
		rm -R /tmp/config.plist
                exit 1
                ;;
            * ) echo "Try again...";;
        esac
    done
fi

# debug
# if [ $gDebug != 0 ]; then
    echo "HDMI audio codec(s)"
        if [ $intelhdmi = 1 ]; then
            echo "Intel:    $Codecintelhdmi"
        fi
        if [ $amdhdmi = 1 ]; then
            echo "AMD:      $Codecamdhdmi"
        fi
        if [ $nvidiahdmi = 1 ]; then
            echo "Nvidia:   $Codecnvidiahdmi"
        fi
# fi

# debug ##
# if [ $gDebug = 0 ]; then
# if [ $gDebug = 1 ]; then
# if [ $gDebug = 2 ]; then
#    echo ""
#    gigfx=0
#    gdgfx=0
#    echo "gigfx = $gigfx"
#    echo "gdgfx = $gdgfx"
# fi

# verify igfx
if [ $gigfx = 0 ]; then  # no IGFX
    echo "Integrated Graphics is not installed/enabled"
    gigfxnuc=0
    rm -R /tmp/config.plist
#    rm -R /tmp/HDEF.txt

else
    gideviceid=$(ioreg -rxn $gigfx | grep device-id | sed -e 's/.*<//' -e 's/>//')

# debug ##
# if [ $gDebug = 0 ]; then
# if [ $gDebug = 1 ]; then
# if [ $gDebug = 2 ]; then
# gideviceid=26010000
# gideviceid=62010000
# gideviceid=12040000
# gideviceid=220d0000
# gideviceid=16160000
# gideviceid=12190000
# gideviceid=26190000
# gideviceid=12590000
# gAudioid=11
# fi

# initialize variable
gideviceidsupported=y
gigfxindex=0
gigfxhdmihdef=n
gigfxhdmihdau=n

# desktop igfx ssdt parameters
    case $gideviceid in

        26010000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,snb-platform-id"| awk '{ print $4 }')
            gigfxgen=2
            gigfxhdmifb=00020300
            gigfxname="HD3000"
            gigfxrepo=hd3000
            gigfxfolder=ssdt_hdmi-hd3000
            gigfxzip=ssdt_hdmi-hd3000-6series-3
            gigfxssdt=SSDT-HDMI-HD3000
            gigfxindex=2
            gigfxhdmihdef=y
            gigfxnuc=0
            ;;

        62010000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=3
            gigfxhdmifb=0A006601
            gigfxname="HD4000"
            gigfxrepo=hd4000
            gigfxfolder=ssdt_hdmi-hd4000
            gigfxzip=ssdt_hdmi-hd4000-7series-3
            gigfxssdt=SSDT-HDMI-HD4000
            gigfxindex=5
            gigfxhdmihdef=y
            gigfxnuc=0
            ;;

        12040000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=4
            gigfxhdmifb=0300220D
            gigfxhdmicodec=0c0c
            gigfxhdmihdau=y
            gigfxname="HD4600+"
            gigfxrepo=8series
            gigfxfolder=ssdt_hdmi-hd4600+
            gigfxzip=ssdt_hdmi-hd4600+
            gigfxssdt=SSDT-HDMI-HD4600+
            gigfxindex=8
            gigfxnuc=0
            ;;

        22160000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=5
            gigfxhdmifb=03001216
            gigfxhdmihdau=y
            gigfxname="HD6200"
            gigfxrepo=9series
            gigfxfolder=ssdt_hdmi-hd6000+
            gigfxzip=ssdt_hdmi-hd6200
            gigfxssdt=SSDT-HDMI-HD6200
            gigfxindex=0
            gigfxnuc=0
            ;;

        12190000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=6
            gigfxhdmifb=00001219
            gigfxhdmihdau=n
            gigfxname="HD530"
            gigfxrepo=100series
            gigfxfolder=ssdt_hdmi_hd5x0
            gigfxzip=ssdt_hdmi-hd530
            gigfxssdt=SSDT-HDMI-HD530
            gigfxindex=14
            gigfxhdmihdef=y
            gigfxport5=1
            gigfxnuc=0
            ;;

        16190000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=6
            gigfxhdmifb=00001219
            gigfxhdmihdau=n
            gigfxname="HD515"
            gigfxrepo=100series
            gigfxfolder=ssdt_hdmi_hd5x0
            gigfxzip=ssdt_hdmi-hd515
            gigfxssdt=SSDT-HDMI-HD515
            gigfxindex=14
            gigfxhdmihdef=y
            gigfxport5=1
            gigfxnuc=0
            ;;

        12590000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=7
            gigfxhdmifb=00001259
            gigfxhdmihdau=n
            gigfxname="HD630"
            gigfxrepo=200series
            gigfxfolder=ssdt_hdmi_hd6x0
            gigfxzip=ssdt_hdmi-hd630
            gigfxssdt=SSDT-HDMI-HD630
            gigfxindex=17
            gigfxhdmihdef=y
            gigfxport5=0
            gigfxnuc=0
            ;;

        * )
            gideviceidsupported=n
                ;;

    esac

# nuc igfx ssdt parameters
    if [[ $gigfxnuc = 1 && $gideviceidsupported = n ]]; then
        gigfxnuc=2
        gideviceidsupported=y
        gigfxportmax=6

        case $gideviceid in

        66010000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=3
            gigfxhdmifb=0A006601
            gigfxname="HD4000"
            gigfxrepo=hd4000
            gigfxfolder=ssdt_hdmi-hd4000
            gigfxzip=ssdt_hdmi-hd4000-7series-3
            gigfxssdt=SSDT-HDMI-HD4000
            gigfxindex=5
            gigfxhdmihdef=y
            gigfxportmax=7
            ;;

        260a0000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=4
            gigfxhdmifb=0300220D
            gigfxhdmihdau=y
            gigfxname="HD5000"
            gigfxrepo=8series
            gigfxfolder=ssdt_hdmi-hd4600+
            gigfxzip=ssdt_hdmi-hd4600+
            gigfxssdt=SSDT-HDMI-HD4600+
            gigfxindex=8
            ;;

        220d0000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=4
            gigfxhdmifb=0300220D
            gigfxhdmihdau=y
            gigfxname="HD5200"
            gigfxrepo=8series
            gigfxfolder=ssdt_hdmi-hd4600+
            gigfxzip=ssdt_hdmi-hd4600+
            gigfxssdt=SSDT-HDMI-HD4600+
            gigfxindex=8
            ;;

        16160000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=5
            gigfxhdmifb=02001616
            gigfxhdmihdau=y
            gigfxname="HD5500"
            gigfxrepo=9series
            gigfxfolder=ssdt_hdmi-hd6000+
            gigfxzip=ssdt_hdmi-hd5500
            gigfxssdt=SSDT-HDMI-HD5500
            gigfxindex=11
            ;;

        26160000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=5
            gigfxhdmifb=04002616
            gigfxhdmihdau=y
            gigfxname="HD6000"
            gigfxrepo=9series
            gigfxfolder=ssdt_hdmi-hd6000+
            gigfxzip=ssdt_hdmi-hd6000
            gigfxssdt=SSDT-HDMI-HD6000
            gigfxindex=11
            ;;

        2B160000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=5
            gigfxhdmifb=04002B16
            gigfxhdmihdau=y
            gigfxname="HD6100"
            gigfxrepo=9series
            gigfxfolder=ssdt_hdmi-hd6000+
            gigfxzip=ssdt_hdmi-hd6100
            gigfxssdt=SSDT-HDMI-HD6100
            gigfxindex=11
            ;;

        26190000* )
            gigfxframebuffer=$(ioreg -rxn $gigfx | grep "AAPL,ig-platform-id"| awk '{ print $4 }')
            gigfxgen=6
            gigfxhdmifb=00002619
            gigfxhdmihdau=n
            gigfxname="HD540"
            gigfxrepo=100series
            gigfxfolder=ssdt_hdmi_hd5x0
            gigfxzip=ssdt_hdmi-hd540
            gigfxssdt=SSDT-HDMI-HD540
            gigfxindex=0
            gigfxhdmihdef=y
            ;;

        * )
            gideviceidsupported=n
            gigfxnuc=0
            ;;

        esac
    fi


    if [ $gideviceidsupported = n ]; then  # IGFX not supported
        echo "Device ID: 0x$gideviceid not supported"
        rm -R /tmp/config.plist
        rm -R /tmp/HDEF.txt

        if [ $gdgfx = 0 ]; then
            echo "AMD/Nvidia not found"
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit 1
        fi
    else

# verify HDEF/layout-id

    case $gAudioid in

        1|2 )
            validaudioid=y
            ;;

        3 )
            if [[ $gigfxname = HD3000 || $gigfxname = HD4000 ]]; then
            validaudioid=y
            fi
            ;;

        * )
            echo "Audio ID: $gAudioid is not valid"
            echo "Audio ID set to Audio ID: 1"
            echo "Edit EFI/CLOVER/ACPI/patched/SSDT-HDEF... to preferred Audio ID"

        while true
            do
            read -p "Audio ID: 1, continue (y/n): " choice5
            case "$choice5" in
                [yY]* )
                    gAudioid=1
                    break
                    ;;
                [nN]* )
                    echo "No system files were changed"
                    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                    exit 1
                    ;;
                * ) echo "Try again...";;
            esac
        done
    esac

# hdef ssdt audio id
    gigfxhdmiaudioid=$gAudioid

# hdef ssdt parameters
    ghdefrepo=ALCInjection
    ghdeffolder=ssdt_hdef

    case $gigfxname in

        HD3000|HD4000* )
            gigfxhdmiaudioid=3
            ghdefzip=ssdt_hdef-$gigfxhdmiaudioid-with_ioreg:hdef
            ghdefssdt=SSDT-HDEF-$gigfxhdmiaudioid
            ;;

        HD515|HD530|HD540*|HD630 )
            if [ $gigfxhdmiaudioid = 3 ]; then gigfxhdmiaudioid=1; fi
            ghdefzip=ssdt_hdef-$gigfxhdmiaudioid-100-hdas
            ghdefssdt=SSDT-HDEF-HDAS-$gigfxhdmiaudioid
            ;;

    esac

# verify IGPU hfa-gfx injection
    igfxhdagfx1=$(ioreg -rxn $gigfx | grep -c "hda-gfx")

# verify HDEF/HDAU hda-gfx injection
    if [ $gigfxhdmihdau = y ]; then
        igfxhdagfx2=$(ioreg -rxn HDAU@3 | grep -c "hda-gfx")
    else
        igfxhdagfx2=$(ioreg -rxn HDEF | grep -c "hda-gfx")
    fi

    igfxhdagfx=$(($igfxhdagfx1 + $igfxhdagfx2))

# debug ##
# if [ $gDebug = 0 ]; then
# if [ $gDebug = 1 ]; then
# if [ $gDebug = 2 ]; then
# echo ""
# igfxhdagfx=0
# igfxhdagfx2=0
# fi

# debug
    if [ $gDebug = 2 ]; then
        echo "igfxhdagfx1 = $igfxhdagfx1"
        echo "igfxhdagfx2 = $igfxhdagfx2"
        igfxhdagfx=$(($igfxhdagfx1 + $igfxhdagfx2))
        echo "igfxhdagfx = $igfxhdagfx"
    fi

# Intel integrated graphics HDMI audio

# initialize variable
    choice1=n
    choice2=n
    gconnectoredit=n
    gssdtinstall=n

    if [ $igfxhdagfx = 2 ]; then  # ssdt working
        Echo "$gigfxname HDMI audio is enabled, connector edit may be required"
        while true
        do
        read -p "Verify $gigfxname HDMI audio connector/s (y/n): " choice1
            case "$choice1" in
                [yY]* ) gconnectoredit=y; break;;
                [nN]* ) gconnectoredit=n; break;;
                * ) echo "Try again...";;
            esac
        done
    else
        Echo "$gigfxname HDMI audio is not enabled"
        while true
        do
        read -p "Install $gigfxssdt HDMI audio ssdt (y/n): " choice2
            case "$choice2" in
                [yY]* ) gssdtinstall=y; break;;
                [nN]* ) gssdtinstall=n; break;;
                * ) echo "Try again...";;
        esac
        done
    fi

    gamdnvidia=n
    if [[ $choice1 = n && $choice2 = n ]]; then
        gdgfx=1  ## debug 2
            if [ $gdgfx = 0 ]; then
                echo "AMD/Nvidia not found"
                echo "No system files were changed"
                echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                exit 1
            fi
    fi

# debug
    if [ $gDebug = 2 ]; then
# echo ""
# gdgfx=0
# gamdnvidia=y
        echo "gdgfx = $gdgfx"
        echo "gamdnvidia = $gamdnvidia"
    fi

    if [ $gssdtinstall = y ]; then # install igfx ssdt
    gconnectoredit=y
        if [ $gDebug = 2 ]; then
            echo "if [ gssdtinstall = y ]; then # install ssdt"
            echo "gdgfx = $gdgfx"
            echo "gamdnvidia = $gamdnvidia"
            echo "gssdtinstall = $gssdtinstall"
            echo "gconnectoredit = $gconnectoredit"
            echo "gigfxrepo = $gigfxrepo"
            echo "gigfxfolder = $gigfxfolder"
            echo "gigfxzip = $gigfxzip"
            echo "gDownloadLink=https://raw.githubusercontent.com/toleda/audio_hdmi_$gigfxrepo/master/$gigfxfolder/$gigfxzip.zip"
        fi

# download igfx ssdt
    echo "Download $gigfxssdt ..."
    gDownloadLink="https://raw.githubusercontent.com/toleda/audio_hdmi_$gigfxrepo/master/$gigfxfolder/$gigfxzip.zip"
    sudo curl -o "/tmp/$gigfxzip.zip" $gDownloadLink
    unzip -qu "/tmp/$gigfxzip.zip" -d "/tmp/"

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: Download failure, verify network - igfx ssdt"
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# debug
    if [[ $gDebug = 2 && $gigfxhdmihdef = y ]]; then
        echo "ghdefrepo = $ghdefrepo"
        echo "ghdeffolder = $ghdeffolder"
        echo "ghdefzip = $ghdefzip"
        echo "gDownloadLink=hthttps://raw.githubusercontent.com/toleda/audio_$ghdefrepo/master/$ghdeffolder/$ghdefzip.zip"
    fi

# download hdef ssdt, HD3000, HD4000, HD515, HD530, HD540, HD630
    if [ $gigfxhdmihdef = y ]; then
        echo "Download $ghdefssdt.aml ..."
        gDownloadLink="https://raw.githubusercontent.com/toleda/audio_$ghdefrepo/master/$ghdeffolder/$ghdefzip.zip"
        sudo curl -o "/tmp/$ghdefzip.zip" $gDownloadLink
        unzip -qu "/tmp/$ghdefzip.zip" -d "/tmp/"
    fi

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: Download failure, verify network - hdef ssdt"
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# install igfx ssdt to EFI/CLOVER/ACPI/patched (cloverHDMI)
    case $gDebug in

    0 )
        if [ -d "$gCloverDirectory/ACPI/patched/$gigfxssdt" ]; then
            sudo rm -R "$gCloverDirectory/ACPI/patched/$gigfxssdt"
# echo "$gCloverDirectory/ACPI/patched/$gigfxssdt deleted"
        fi
        sudo cp -R "/tmp/$gigfxzip/$gigfxssdt.aml" "$gCloverDirectory/ACPI/patched/"

# exit if error
        if [ "$?" != "0" ]; then
            echo Error: ssdt copy failure
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit 1
        fi

        echo "$gCloverDirectory/ACPI/patched/$gigfxssdt installed"

        if [ $gigfxhdmihdef = y ]; then
            if [ -d "$gCloverDirectory/ACPI/patched/$ghdefssdt" ]; then
                sudo rm -R "$gCloverDirectory/ACPI/patched/$ghdefssdt"
# echo "$gCloverDirectory/ACPI/patched/$ghdefssdt deleted"
            fi
            sudo cp -R "/tmp/$ghdefzip/$ghdefssdt.aml" "$gCloverDirectory/ACPI/patched/"

# exit if error
            if [ "$?" != "0" ]; then
                echo Error: ssdt copy failure
                echo "No system files were changed"
                echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                echo "$gigfxname HDEF audio ssdt copied to Desktop"
            fi

            echo "$gCloverDirectory/ACPI/patched/$ghdefssdt installed"
        fi
        ;;

    1|2 )
        sudo cp -R "/tmp/$gigfxzip/$gigfxssdt.aml" "Desktop/$gigfxname-$gigfxssdt.aml"

# exit if error
        if [ "$?" != "0" ]; then
            echo Error: ssdt copy failure
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit 1
        fi
# echo "Debug mode"
        echo "$gigfxname HDMI audio ssdt copied to Desktop"

        if [ $gigfxhdmihdef = y ]; then
            sudo cp -R "/tmp/$ghdefzip/$ghdefssdt.aml" "Desktop/$gigfxname-$ghdefssdt.aml"

# exit if error
            if [ "$?" != "0" ]; then
                echo Error: ssdt copy failure
                echo "No system files were changed"
                echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
                echo "$gigfxname HDEF audio ssdt copied to Desktop"
            fi
#    	echo "No system files were changed"
        fi
        ;;

    esac

# cleanup /tmp
    sudo rm -R /tmp/$gigfxzip.zip
    sudo rm -R /tmp/$gigfxzip
    # sudo rm -R /tmp/IGPU.txt
    # sudo rm -R /tmp/HDEF.txt
    sudo rm -R /tmp/__MACOSX

    if [ $gigfxhdmihdef = y ]; then
        sudo rm -R /tmp/$ghdefzip.zip
        sudo rm -R /tmp/$ghdefzip
    fi

# exit if error
    if [ "$?" != "0" ]; then
        sudo rm -R "$gCloverDirectory/ACPI/patched/$gigfxssdt"
        echo Error: ssdt install failure
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

    fi  # igfx ssdt installed
    gssdtinstall=OK

# verify igfx framebuffers
    if [ $gconnectoredit = y ]; then # verify framebuffers
    index=$gigfxport5
    indexmax=$((gigfxport5 + gigfxports - 1))
    port=5
    iaudio=0

    while [ $index -le $indexmax ]; do

# debug
    if [ $gDebug = 2 ]; then
        echo "index = $index"
        echo "port = $port"
    fi

# look for display(s)
    ioreg -rw 0 -p IOService -n AppleIntelFramebuffer@$index > /tmp/IGPU.txt
    audioinfo[$port]=$(cat /tmp/IGPU.txt | grep -c "audio-codec-info")
    connector[$port]=$(cat /tmp/IGPU.txt | grep connector-type | sed -e 's/.*<//' -e 's/>//')
    iaudio=$(($iaudio + ${audioinfo[$port]}))


# debug
    if [ $gDebug = 2 ]; then
        echo "audioinfo = ${audioinfo[$port]}"
        echo "connector = ${connector[$port]}"
        echo "iaudio = $iaudio"
    fi

    index=$((index + 1))
    port=$((port + 1))
    rm -R /tmp/IGPU.txt
    done

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: framebuffer analysis failed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# verify hdmi display, max 1
# initialize variable
    gamdnvidia=n

    case $iaudio in

    0 )
        echo "No display connected to $gigfxname"
        gdgfx=1  ## debug 2
        if [ $gdgfx = 0 ]; then
            echo "Error: patch not possible"
            echo "AMD/Nvidia not found"
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit 1
        fi
        ;;

    1 )
        echo "One display connected, proceeding"
        ;;

    2 )
        if [[ $gigfxgen = 4 || $gigfxgen = 5 || $gigfxgen = 6 || $gigfxgen = 7 ]]; then
            echo "Two displays connected, proceeding"
        else
            echo "Error: more than one display connected to $gigfxname, patch not possible"
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit 1
        fi
        ;;

    3 )
        if [ $gigfxhdmihdau = y ]; then
            echo "Error: more than two displays connected to $gigfxname, patch not possible"
        else
            echo "Error: more than one display connected to $gigfxname, patch not possible"
        fi
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    ;;

    * )
        echo Error: display analysis failed
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
        ;;

    esac

# debug
    if [ $gDebug = 2 ]; then
    echo "gdgfx = $gdgfx"
    echo "gamdnvidia = $gamdnvidia"
    fi

# exit if error
    if [ "$?" != "0" ]; then
        echo Error: display analysis failed
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# debug
    if [ $gDebug = 2 ]; then
    echo ""
    # gigfxname="HD3000"
    # gigfxname="HD6200"
    fi

# verify native hdmi connector
    ifbnative=0

case $gigfxname in

    HD3000|HD4000* ) # native HDMI connector
        connector7=${connector[7]}
        if [[ $connector7 == "00080000" ]]; then  # native hdmi
            echo "Native $gigfxname/port 0x7 is HDMI connector, no patch required"
            ifbnative=1
        fi
        ;;

    HD6200|HD540* ) # connector detection, 515, 530 removed special case
        echo "$gigfxname/$gigfxhdmifb detects and sets HDMI connector, no patch required"
        ifbnative=1
        ;;

    esac

# no fb patch required
    if [ $ifbnative = 1 ]; then  # native fb
        sudo rm -R /tmp/config.plist
        rm -R /tmp/HDEF.txt

    else

# confirm ports to edit
    port=5

# debug
    if [ $gDebug = 2 ]; then
        echo "gigfxportmax = $gigfxportmax"
    fi

    choice3=n
    while [ $port -le $gigfxportmax ]; do
# debug
        if [ $gDebug = 2 ]; then
            echo "port = $port"
            echo "audioinfo = ${audioinfo[$port]}"
            echo "connector = ${connector[$port]}"
            echo "iaudio = $iaudio"
        fi

        if [ ${audioinfo[$port]} != 0 ]; then
            while true; do
            read -p "Confirm DP to HDMI connector edit on port 0x$port (y/n): " choice3
            case "$choice3" in
                [yY]* ) echo "Patch port 0x$port"; gifgxfbedit=y; break;;
                [nN]* ) echo "Ignore port 0x$port"; audioinfo[$port]=0; iaudio=$(($iaudio-1)); break;;
                * ) echo "Try again...";;
            esac
            done

# debug
            if [ $gDebug = 2 ]; then
                echo "port = $port"
                echo "iaudio = $iaudio"
                echo "audioinfo = ${audioinfo[$port]}"
                echo "connector = ${connector[$port]}"
                echo "iaudio = $iaudio"
            fi
        fi

    port=$(($port + 1))
    done

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: config.plst edit failed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

    if [ $iaudio = 0 ]; then  # no framebuffer edits
        echo "No framebuffer edits requested"
        rm -R /tmp/config.plist
#    rm -R /tmp/HDEF.txt

    else

# download connector edits
    case $gDebug in

        0|1 )
            echo "Download $gigfxname HDMI audio connector edits ..."
            gDownloadLink="https://raw.githubusercontent.com/toleda/audio_cloverHDMI/master/config-audio_cloverHDMI+.plist.zip"

            sudo curl -o "/tmp/config-audio_cloverHDMI+.plist.zip" $gDownloadLink
            unzip -qu "/tmp/config-audio_cloverHDMI+.plist.zip" -d "/tmp/"
            mv /tmp/config-audio_cloverHDMI+.plist /tmp/config-audio_cloverHDMI.plist
            ;;

        2 )
            echo "gDesktopDirectory = $gDesktopDirectory"

            if [ -f "$gDesktopDirectory/config-audio_cloverHDMI+.plist" ]; then
                sudo cp -R "$gDesktopDirectory/config-audio_cloverHDMI+.plist" /tmp/config-audio_cloverHDMI.plist
                echo "Desktop/config-audio_cloverHDMI+.plist copied to /tmp/config-audio_cloverHDMI.plist"
            else
                echo "Error, Desktop/config-audio_cloverHDMI+.plist missing"
                exit 1
            fi
            ;;

    esac

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: config-audio_cloverHDMI.plist download failed"
        echo "Verify Insternel access"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# verify /tmp/config-audio_cloverHDMI.plist
    index=0
    sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches:KextsToPatch:${patch[$index]}'" /tmp/config-audio_cloverHDMI.plist -x > "/tmp/ktp.plist"
    if [ $(sudo /usr/libexec/PlistBuddy -c "Print '::$index dict'" /tmp/ktp.plist | grep -c "AppleHDAController") = 0 ]; then
        echo "Error: config-audio_cloverHDMI.plist patches failed"
        echo "Verify Insternel access"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
       exit 1
    fi

# remove t2- patches (cloverHDMI)
    ktpexisting=$(sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches:KextsToPatch:'" /tmp/config.plist | grep -c "t2-")

# debug
    if [ $gDebug = 2 ]; then
        echo "ktpexisting - t2- = $ktpexisting"
    fi

    index=0
    while [ $ktpexisting -ge 1 ]; do
        if [ $(sudo /usr/libexec/PlistBuddy -c "Print ':KernelAndKextPatches:KextsToPatch:$index dict'" /tmp/config.plist | grep -c "t2-") = 1 ]; then
            sudo /usr/libexec/PlistBuddy -c "Delete ':KernelAndKextPatches:KextsToPatch:$index dict'" /tmp/config.plist
            ktpexisting=$((ktpexisting - 1))
            index=$((index - 1))
        fi
        index=$((index + 1))

# debug
        if [ $gDebug = 2 ]; then
            echo "index = $index"
            echo "ktpexisting = $ktpexisting"
        fi
    done

# patch summary
# iaudio=1 # number of connector edits
# audioinfo[5]=1 # audio on port 0x5
# audioinfo[6]=0 # audio on port 0x5
# audioinfo[7]=0 # audio on port 0x5
# connector[5]=00040000 # native port 0x5 connector
# connector[6]=00040000 # native port 0x6 connector
# connector[7]=00040000 # native port 0x7 connector

# config-audio_cloverHDMI.plist/.../KextsToPatch
# Item 0: 10.9-10.11-HD4600_HDMI_Audio-1of2 Item 0 + Item 1
# Item 1: 10.9-10.11-HD4600_HDMI_Audio-2of2
# Item 2: 10.10-10.11-SNB-Port _0x5-DP2HDMI Item 2 + Item 4
# Item 3: 10.10-10.11-SNB-Port _0x6-DP2HDMI Item 3 + Item 4
# Item 4: 10.10-10.11-SNB-Port _0x7-DP2HDMI
# Item 5: 10.10-10.11-Capri-Port _0x5-DP2HDMI Item 5 + Item 7
# Item 6: 10.10-10.11-Capri-Port _0x6-DP2HDMI Item 6 + Item 7
# Item 7: 10.10-10.11-Capri-Port _0x7-HDMI2DP
# Item 8: 10.10-10.11-Azul-Port_0x5-DP2HDMI
# Item 9: 10.10-10.11-Azul-Port_0x6-DP2HDMI
# Item 10: 10.10-10.11-Azul-Port_0x7-DP2HDMI
# Item 11: 10.10-10.11-BDW010509-Port_0x5-DP2HDM (010509)
# Item 12: 10.10-10.11-BDW010509-Port_0x5-DP2HDM (01050b)
# Item 13: 10.11.4-SKL-1912000-4_displays
# Item 14: 10.11.4-SKL-1912000-Port_0x5-DP2HDM (010509)
# Item 15: 10.11.4-SKL-1912000-Port_0x6-DP2HDM (02040a)
# Item 16: 10.11.4-SKL-1912000-Port_0x7-DP2HDM (03060a)
# Item 17: 10.12.6-KBL-5912000-Port_0x5-DP2HDM (010509)
# Item 18: 10.12.6-KBL-5912000-Port_0x6-DP2HDM (02040a)
# Item 19: 10.12.6-KBL-5912000-Port_0x7-DP2HDM (03060a)

# debug
    if [ $gDebug = 2 ]; then
        echo "gigfxhdmicodec = $gigfxhdmicodec"
    fi

# codec patch hd4600 audio controller/credit TimeWalker75a
    if [ $gigfxhdmicodec = "0c0c" ]; then
        patch=1
        _patchconfig
        patch=0
        _patchconfig
    fi

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: config.plst/.../hd4600 audio controller edit failed"
        echo “Original config.plist restored”
        sudo cp -X $gCloverDirectory/config-backup.plist $gCloverDirectory/config.plist
        sudo rm -R /tmp/ktp.plist
        sudo rm -R /tmp/config.plist
        sudo rm -R /tmp/config-audio_cloverHDMI+.plist.zip
        sudo rm -R /tmp/config-audio_cloverHDMI.plist
        sudo rm -R /tmp/__MACOSX
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# hd515,hd530 4 port edit
    if [ $gigfxhdmifb = "00001219" ]; then
        patch=13
        _patchconfig
    fi

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: config.plst/.../4 port edit failed"
        echo “Original config.plist restored”
        sudo cp -X $gCloverDirectory/config-backup.plist $gCloverDirectory/config.plist
        sudo rm -R /tmp/ktp.plist
        sudo rm -R /tmp/config.plist
        sudo rm -R /tmp/config-audio_cloverHDMI+.plist.zip
        sudo rm -R /tmp/config-audio_cloverHDMI.plist
        sudo rm -R /tmp/__MACOSX
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# patch framebuffer
    case $gigfxgen in

    2|3 )
        if [ ${audioinfo[5]} = 1 ]; then
            patch[0]=$gigfxindex
        fi
        if [ ${audioinfo[6]} = 1 ]; then
            patch[0]=$(($gigfxindex+1))
        fi
        patch[1]=$(($gigfxindex+2))
        ;;

    4|5|6|7 )

        index=0
        port=5

# debug
        if [ $gDebug = 2 ]; then
        echo "gigfxportmax = $gigfxportmax"
        fi

# add frameuffer patch to config.plist
        while [ $port -le $gigfxportmax ]; do
            if [ ${audioinfo[$port]} != 0 ]; then
                index=$(($index + 1))
                patch=$(($gigfxindex + $port - 5))
                _patchconfig
            fi
        port=$(($port + 1))
        done
        ;;

    * )
        echo "Intel HD Graphics Gen $gigfxgen is not supported"
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
        ;;

    esac

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: config.plst/.../framebuffer edit failed"
        echo “Original config.plist restored”
        sudo cp -X $gCloverDirectory/config-backup.plist $gCloverDirectory/config.plist
        sudo rm -R /tmp/ktp.plist
        sudo rm -R /tmp/config.plist
        sudo rm -R /tmp/config-audio_cloverHDMI+.plist.zip
        sudo rm -R /tmp/config-audio_cloverHDMI.plist
        sudo rm -R /tmp/__MACOSX
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# install updated config.plst
    case $gDebug in

    0 )
        sudo cp -R "/tmp/config.plist" "$gCloverDirectory/config.plist"
        echo "HDMI audio edited $gCloverDirectory/config.plist installed"
        ;;

    1|2 )
        if [ -f "Desktop/$gigfxname-config.plist" ]; then
            sudo rm -R "Desktop/$gigfxname-config.plist"
        fi
        sudo cp -R "/tmp/config.plist" "Desktop/$gigfxname-config.plist"
        echo "$gigfxname HDMI audio edited config.plist copied to Desktop"
        ;;

    esac

# cleanup /tmp
    sudo rm -R /tmp/config.plist
    sudo rm -R /tmp/ktp.plist
#     sudo rm -R /tmp/config-audio_cloverHDMI+.plist.zip
    sudo rm -R /tmp/config-audio_cloverHDMI.plist
#     sudo rm -R /tmp/__MACOSX


    fi  # no framebuffer edits

    fi  # verify framebuffers
    fi  # a fb
fi  # IGFX not supported
fi  # no IGFX

# debug
if [ $gDebug = 2 ]; then
    echo "AMD/Nvidia discrete graphics HDMI audio"
    echo "gigfx = $gigfx"
    echo "gdgfx = $gdgfx"
fi

# AMD/Nvidia discrete graphics HDMI audio

if [ $gigfxnuc = 0 ]; then  # AMD/Nvidia else nuc

while true
do
    read -p "Install AMD/Nvidia HDMI audio (y/n): " choice8
    case "$choice8" in
        [yY]* ) gdgfxhdmi=y; break;;
        [nN]* ) gdgfxhdmi=n; break;;
        * ) echo "Try again...";;
    esac
done

if [ $gdgfxhdmi = y ]; then  # AMD/Nvidia HDMI audio

# get acpi pcie device name
    numname1=14
    gdgfxname1[1]=PEG0@1
    gdgfxname1[2]=PEG1@1
    gdgfxname1[3]=PEGP@1
    gdgfxname1[4]=P0P1@1
    gdgfxname1[5]=P0P2@1
    gdgfxname1[6]=P0P2@3
    gdgfxname1[7]=NPE3@2
    gdgfxname1[8]=NPE3@3
    gdgfxname1[9]=NPE7@3
    gdgfxname1[10]=pci-bridge@1
    gdgfxname1[11]=pci-bridge@3
    gdgfxname1[12]=BR3A@3
    gdgfxname1[13]=PC02@3
    gdgfxname1[14]=PC12@3

    index=1
    while [ $index -le $numname1 ]; do
    dgfxpciname=$(ioreg -rxn ${gdgfxname1[$index]} | grep vendor-id| awk '{ print $4 }')

# debug
    if [ $gDebug = 2 ]; then
        echo "gdgfxname1 = ${gdgfxname1[$index]}"
    fi

    if [ -n "${dgfxpciname}" ]; then
        dgfxindex1=$index
        index=$(($numname1 + 1))

# debug
        if [ $gDebug = 2 ]; then
            echo "dgfxindex1 = $dgfxindex1"
        fi

    fi

    index=$(($index + 1))
    done

    gdgfxpciname1=${gdgfxname1[$dgfxindex1]}

# debug
    if [ $gDebug = 2 ]; then
        echo "gdgfxpciname1 = ${gdgfxname1[$dgfxindex1]}"
        echo "gdgfxpciname1 = $gdgfxpciname1"
    fi

    if [ $gdgfxpciname1 = 0 ]; then
        echo "Error: discrete graphics card not found, unknown acpi PCI0 name"
        echo "Names checked: ${gdgfxname1[@]}"
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# get acpi graphics device name
    numname2=8
    gdgfxname2[1]=PEGP@0
    gdgfxname2[2]=GFX0@0
    gdgfxname2[3]="display@0"
    gdgfxname2[4]="pci-display@0"
    gdgfxname2[5]=GFX1@0
    gdgfxname2[6]=H000@0
    gdgfxname2[7]=pci10de
    gdgfxname2[8]=pci1002

#find discrete graphics vendor-id
    index=1
    while [ $index -le $numname2 ];
    do
    dgfxvendorid=$(ioreg -rxn ${gdgfxname2[$index]} | grep vendor-id| awk '{ print $4 }')
    dgfxdeviceid=$(ioreg -rxn ${gdgfxname2[$index]} | grep device-id| awk '{ print $4 }')

    if [ $gDebug = 2 ]; then
        echo "gdgfxname2 = ${gdgfxname2[$index]}"
    fi

    if [ -n "${dgfxvendorid}" ]; then
        gdgfxpciname2=${gdgfxname2[$index]}

        index0=1
        for vendor in $dgfxvendorid
        do

# debug
        if [ $gDebug = 2 ]; then
            echo "index0 = $index, vendor-id = ${vendor:1:4}"
        fi

# sort discrete graphics vendors and devices
        case ${vendor:1:4} in

            0210 ) gdgfxvendorid=${vendor:1:4}
                gdgfxname=AMD
                ;;

            de10 ) gdgfxvendorid=${vendor:1:4}
                gdgfxname=Nvidia
            ;;
        esac
        index0=$((index0 + 1))
        done

# find discrete graphics  device-id
        index0=1
        for device in $dgfxdeviceid
        do

# debug
            if [ $gDebug = 2 ]; then
                echo "index0 = $index, device-id = ${device:1:4}"
            fi

            gdgfxdeviceid=${device:1:4}

            index0=$((index0 + 1))
        done
    fi

    index=$(($index + 1))
    done

# dgfx found
    gdgfxvendorid=${gdgfxvendorid:2:2}${gdgfxvendorid:0:2}
    gdgfxdeviceid=${gdgfxdeviceid:2:2}${gdgfxdeviceid:0:2}

# debug ##
# if [ $gDebug = 0 ]; then
# if [ $gDebug = 1 ]; then
# if [ $gDebug = 2 ]; then
#     echo "gdgfxpciname1 = $gdgfxpciname1"
#     echo "gdgfxpciname2 = $gdgfxpciname2"
#     echo "gdgfxvendorid = ${gdgfxvendorid}"
#     echo "gdgfxdeviceid = ${gdgfxdeviceid}"
#     gdgfxpciname1=BR3A@3
#     gdgfxpciname2=H060@0
#     echo "gdgfxvendorid = ${gdgfxvendorid}"
#     echo "gdgfxdeviceid = ${gdgfxdeviceid}"
# gdgfxvendorid=""
# fi


    if [ $gdgfxpciname1 = "BR3A@3" ]; then
        if [[ $gdgfxpciname1 = "BR3A@3" && $gdgfxpciname2 = "H000@0" ]]; then
            echo "X99 HDMI audio supported"
        else

# debug
        if [ $gDebug = 2 ]; then
            echo "gdgfxpciname1 = $gdgfxpciname1"
            echo "gdgfxpciname2 = $gdgfxpciname2"
            echo
        fi

        gdgfxpciname2="Hxx0@0"
        echo "NOTE:ACPI graphics name unknown, H000 installed"
        echo "Verify IOReg/BR3A/graphics name, i.e., Hxx0@0 and Hxx1@0,1"
        echo "Before restarting, edt EFI/CLOVER/ACPI/patched/SSDT-HDMI-...-$gdgfxpciname1"
        echo "MaciASL/Edit/Find: H000/Replace: Hxx0"
        echo "MaciASL/Edit/Find: H001/Replace: Hxx1"
        echo "Compile/Save/Restart"
        echo "More information, see Desktop/[Guide] macOS hdmi audio x99 ssdt"

        while true
        do
            read -p "AMD(a)/Nvidia(n) graphics (a/n): " choice6
            case "$choice6" in
                [aA]* ) gdgfxname="AMD"; break;;
                [nN]* ) gdgfxname="Nvidia"; break;;
            * ) echo "Try again...";;
            esac
        done

    fi
    fi

    if [ -z "${gdgfxvendorid}" ]; then
        if [ $gdgfxpciname1 = "BR3A@3" ]; then
            if [ $gDebug = 2 ]; then
                echo "gdgfxpciname1 = $gdgfxpciname1"
	            echo "gdgfxvendorid = $gdgfxvendorid"
            fi

        else
            if [ $gdgfx != 0 ]; then
                echo "AMD/Nvidia HDMI codec found"
            fi
            echo "AMD/Nvidia graphics not found, unknown acpi PCI0/graphics name"
            echo "Names checked: ${gdgfxname2[@]}"
            echo "No system files were changed"
            echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
            exit
        fi
    fi

    if [ $gdgfxpciname2 = "Hxx0@0" ]; then
        dgfxhdagfx=0

        else
        echo "$gdgfxname discrete graphics card $gdgfxvendorid$gdgfxdeviceid found on $gdgfxpciname1/$gdgfxpciname2"

# verify GFX0 hfa-gfx injection
        dgfxhdagfx1=$(ioreg -rxn $gdgfxpciname2 | grep -c "hda-gfx")

# verify HDAU hda-gfx injection
        dgfxhdagfx2=$(ioreg -rxn HDAU@0,1 | grep -c "hda-gfx")

        dgfxhdagfx=$(($dgfxhdagfx1 + $dgfxhdagfx2))

# debug
        if [ $gDebug = 2 ]; then
            echo "dgfxhdagfx1 = $dgfxhdagfx1"
            echo "dgfxhdagfx2 = $dgfxhdagfx2"
            dgfxhdagfx=$(($dgfxhdagfx1 + $dgfxhdagfx2))
            echo "dgfxhdagfx = $dgfxhdagfx"
        fi

    fi

# debug ##
# if [ $gDebug = 0 ]; then
# if [ $gDebug = 1 ]; then
# if [ $gDebug = 2 ]; then
# echo ""
# dgfxhdagfx=0
# fi

# dgfx hdmi audio enabled?
    choice1=n
    if [ $dgfxhdagfx = 2 ]; then  # ssdt working
        echo "$gdgfxname HDMI audio is enabled"
        if [ $gdgfxname = "AMD" ]; then
	        echo "Frambuffer injection and connector patching may also be required"
	        echo "Note: AMD kext edits are not available with this script"
        fi
        echo "Script exits when another HDMI audio method is installed"
        echo "Remove existing HDMI audio method, restart, run cloverHDMI"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 0
    else
        Echo "$gdgfxname HDMI audio is not enabled"
        while true
        do
        read -p "Install $gdgfxname HDMI audio ssdt (y/n): " choice1
        case "$choice1" in
            [yY]* ) gssdtinstall=y; break;;
            [nN]* ) echo "No system files were changed"; exit;;
            * ) echo "Try again...";;
        esac
        done
    fi

    if [ $gdgfxpciname1 = "pci-bridge@1" ]; then

# debug
        if [ $gDebug = 2 ]; then
            echo "gdgfxpciname1 = $gdgfxpciname1"
            echo
        fi
        gdgfxpciname1="PEGP@1"
    fi

    if [ $gdgfxpciname1 = "pci-bridge@3" ]; then

# debug
        if [ $gDebug = 2 ]; then
            echo "gdgfxpciname1 = $gdgfxpciname1"
            echo
        fi
        gdgfxpciname1="PEGP@3"
    fi

# debug
    if [ $gDebug = 2 ]; then
        echo "gdgfxpciname1 = $gdgfxpciname1"
        echo
    fi

# ssdt repo, folder, file
    case $gdgfxname in

        AMD* )
            gdgfxrepo=amd-nvidia
            gdgfxfolder=ssdt_hdmi-amd
            gdgfxzip=ssdt_hdmi-amd-default-
            gdgfxssdt=SSDT-HDMI-AMD-
            ;;

        Nvidia* )
            gdgfxrepo=amd-nvidia
            gdgfxfolder=ssdt_hdmi-nvidia
            gdgfxzip=ssdt_hdmi-nvidia-
            gdgfxssdt=SSDT-HDMI-NVIDIA-
            ;;

    esac

    if [ ${gdgfxpciname1:0:4} = "PEGP" ];then
        gdgfxpciname1=${gdgfxpciname1:0:6}
    else
        gdgfxpciname1=${gdgfxpciname1:0:4}
    fi

    if [ $gdgfxpciname1 = "GFX1" ];then
        gdgfxpciname1="GFX0"
        echo "NOTE :GFX1 is not available, GFX0 installed"
        echo "Before restarting. edt EFI/CLOVER/ACPI/patched/$gdgfxzip$gdgfxpciname1"
        echo "MaciASL/Edit/Find: GFX0/Replace: GFX1/Compile/Save/Restart"
    fi

# debug
    if [ $gDebug = 2 ]; then
        echo "gdgfxrepo = $gdgfxrepo"
        echo "gdgfxfolder = $gdgfxfolder"
        echo "gdgfxzip = $gdgfxzip"
        echo "gDownloadLink=https://raw.githubusercontent.com/toleda/audio_hdmi_$gdgfxrepo/master/$gdgfxfolder/$gdgfxzip$gdgfxpciname1.zip"
    fi

# download ssdt
    echo "Download $gdgfxssdt$gdgfxpciname1 ..."
    gDownloadLink="https://raw.githubusercontent.com/toleda/audio_hdmi_$gdgfxrepo/master/$gdgfxfolder/$gdgfxzip$gdgfxpciname1.zip"

# debug
    if [ $gDebug = 2 ]; then
        echo "sudo curl -o /tmp/$gdgfxzip$gdgfxpciname1.zip $gDownloadLink"
        echo
    fi

    sudo curl -o "/tmp/$gdgfxzip$gdgfxpciname1.zip" $gDownloadLink
    unzip -qu "/tmp/$gdgfxzip$gdgfxpciname1.zip" -d "/tmp/"

# exit if error
    if [ "$?" != "0" ]; then
        echo "Error: Download failure, verify network".
        echo "No system files were changed"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        exit 1
    fi

# install dgfx ssdt to EFI/CLOVER/ACPI/patched (cloverHDMI)

    case $gDebug in

    0 )
        if [ -d "$gCloverDirectory/ACPI/patched/$gdgfxssdt$gdgfxpciname1.aml" ]; then
            sudo rm -R "$gCloverDirectory/ACPI/patched/$gdgfxssdt$gdgfxpciname1.aml"
            # echo "$gCloverDirectoryACPI/patched/$gdgfxssdt$gdgfxpciname1.aml deleted"
        fi
        sudo cp -R "/tmp/$gdgfxzip$gdgfxpciname1/$gdgfxssdt$gdgfxpciname1.aml" "$gCloverDirectory/ACPI/patched/$gdgfxssdt$gdgfxpciname1.aml"
        echo "$gCloverDirectory/ACPI/patched/$gdgfxssdt$gdgfxpciname1.aml installed"
        if [ $gdgfxpciname2 = "Hxx0@0" ]; then
            cp -R /tmp/$gdgfxzip$gdgfxpciname1/'[Guide] macOS hdmi audio x99 ssdt.pdf' Desktop/'[Guide] macOS hdmi audio x99 ssdt'
        fi
        ;;

    1|2 )
        sudo cp -R "/tmp/$gdgfxzip$gdgfxpciname1/$gdgfxssdt$gdgfxpciname1.aml" "Desktop/$gdgfxname-$gdgfxssdt$gdgfxpciname1.aml"
        echo "$gdgfxname HDMI audio ssdt copied to Desktop"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        if [ $gdgfxpciname2 = "Hxx0@0" ]; then
            cp -R /tmp/$gdgfxzip$gdgfxpciname1/'[Guide] macOS hdmi audio x99 ssdt.pdf' Desktop/'[Guide] macOS hdmi audio x99 ssdt'
        fi
        echo "No system files were changed"
# cleanup /tmp
        sudo rm -R /tmp/$gdgfxzip$gdgfxpciname1.zip
        sudo rm -R /tmp/$gdgfxzip$gdgfxpciname1
        # rm -R /tmp/config.plist
        rm -R /tmp/__MACOSX
        # rm -R /tmp/HDEF.txt
        #  rm -R /tmp/IGPU.txt
        exit 0
        ;;

    esac

# cleanup /tmp
    sudo rm -R /tmp/$gdgfxzip$gdgfxpciname1.zip
    sudo rm -R /tmp/$gdgfxzip$gdgfxpciname1
    sudo rm -R /tmp/__MACOSX

fi  # AMD/Nvidia HDMI audio
fi  # AMD/Nvidia

# exit if error
if [ "$?" != "0" ]; then
    sudo rm -R "$gCloverDirectory/ACPI/patched/$gigfxssdt"
    echo Error: ssdt install failure
    echo "No system files were changed"
    echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
    exit 1
fi

case $gDebug in
    0 )
        echo ""
        echo "Install finished, restart required."
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        ;;

    1|2 )
        echo ""
        echo "To install HDMI audio, set gDebug=0, save, run cloverHDMI"
        echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
        ;;

esac

exit 0
