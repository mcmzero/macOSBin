#!/bin/bash
#
# Simple Main Logic Board (MLB) Serial Generator Script by TheRacerMaster
# Based off the work of Hanger1, AGuyWhoIsBored & Alien:X
# NOTE: This is a simple script that doesn't do any checking of other SMBIOS values. It needs valid SMBIOS data which includes the following:
# - Valid SmUUID value in Clover config.plist under SMBIOS (generated using uuidgen)
# - ROM value set to UseMacAddr0 in Clover config.plist (uses MAC address of your first NIC as ROM value)
# - Properly formatted serial number (doesn't have to be a real one, just formatted properly) in Clover config.plist under SMBIOS
#    - Don't use a generic serial number (such as Clover's default)! It needs to be at least semi-unique.
#    - Try using a generated serial number that isn't real (but formatted correctly) from Clover Configurator, Chameleon Wizard, etc.
#    - You can check if a serial number is real here: https://selfsolve.apple.com/agreementWarrantyDynamic.do
#
# After getting a value, insert it in Clover config.plist under RtVariables -> MLB, then reboot
# Try logging into iMessage. If you get a customer code, call Apple and go through the process.
# iMessage should work after going through the customer support process.
#
# Changelog:
# Version 1.1 - Add user input support; you can now input a serial number (as an argument: ./simpleMLB.sh XXXXXXXXXXXX) and the script will use that to generate a MLB
# Version 1.2 - Add more input checks for valid serial number and working internet connection; added support for generating 13 character MLB (does it if serial number is 11 characters)
# Version 1.3 - Fixed some bugs; removed internet connection requirement; now, the script gets week and year numbers from the serial number itself (more accurate than random generation)
# Version 1.4 - Added debug mode which prints info about the serial number and each step of the MLB generation process

# If user input is valid, use that instead of the serial number of the current machine from IORegistry
if [ ! -z "$1" -a ${#1} == 11 ]; then
	MLBFormat=1 # 11 character SN = 13 character MLB
	SN="$1"
elif [ ! -z "$1" -a ${#1} == 12 ]; then
	MLBFormat=2 # 12 character SN = 17 character MLB
	SN="$1"
# Otherwise use the serial number of the current machine from IORegistry
else
	SN=$(ioreg -l | awk '/IOPlatformSerialNumber/ { print $4;}' | cut -d'"' -f2)
	if [ ${#SN} == 11 ]; then
		MLBFormat=1
	elif [ ${#SN} == 12 ]; then
		MLBFormat=2
	else
		echo "Error: Invalid serial number in IORegistry!"
		exit 128
	fi
fi
# Check for debug mode
if [ "$1" == "-debug" ] || [ "$2" == "-debug" ]; then
	debug=1
fi

# Debug
if [ "$debug" == 1 ]; then
	if [ "$MLBFormat" == 1 ]; then
		echo "Input serial number:" $SN "(12 characters)"
	else
		echo "Input serial number:" $SN "(13 characters)"
	fi
fi

# Get the manufacture year from the serial number
if [ "$MLBFormat" == 1 ]; then
	serialNumberYear=$(echo $SN | cut -c 3) # 11-digit serials store the year in the serial number, so we'll just use that
else
	serialNumberYear=$(echo $SN | cut -c 4) # 12-digit serials store them as letters, so we'll need to decode them first
	case "$serialNumberYear" in
		C | D) manufactureYear=0;;
		F | G) manufactureYear=1;;
		H | J) manufactureYear=2;;
		K | L) manufactureYear=3;;
		M | N) manufactureYear=4;;
		P | Q) manufactureYear=5;;
		R | S) manufactureYear=6;;
		T | V) manufactureYear=7;;
		W | X) manufactureYear=8;;
		Y | Z) manufactureYear=9;;
		*)
			echo "Error: Invalid serial number (reason: invalid year)!"
			exit 128;;
	esac
fi

# Debug
if [ "$debug" == 1 ]; then
	if [ "$MLBFormat" == 1 ]; then
		case "$serialNumberYear" in
			0) year=2010;;
			1) year=2011;;
			2) year=2002;;
			3) year=2003;;
			4) year=2004;;
			5) year=2005;;
			6) year=2006;;
			7) year=2007;;
			8) year=2008;;
			9) year=2009;;
		esac
	else
		case "$manufactureYear" in
			0) year=2010;;
			1) year=2011;;
			2) year=2012;;
			3) year=2013;;
			4) year=2014;;
			5) year=2015;;
			6) year=2016;;
			7) year=2017;;
			8) year=2018;;
			9) year=2019;;
		esac
	fi	
	echo "Year of manufacture (from serial number):" $year
fi

# Get the week number from the serial number
if [ "$MLBFormat" == 1 ]; then # 11-digit serial numbers store the week number as two digits, so no decoding needed
	if [[ $(echo $SN | cut -c 4-5) =~ ^-?[01-53]+$ ]]; then
		weekNumber=$(echo $SN | cut -c 4-5)
	else
		echo "Error: Invalid serial number (reason: invalid week number)!"
		exit 128
	fi
else
	serialNumberYear=$(echo $SN | cut -c 4)
	case "$serialNumberYear" in
		D | G | J | L | N | Q | S | V | X | Z) weekNumber=27;; # These serial number year values are offset by 27 weeks
	esac
	serialNumberWeek=$(echo $SN | cut -c 5)
	case "$serialNumberWeek" in
		[1-9]) ((weekNumber+=$serialNumberWeek));;
		C) ((weekNumber+=10));;
		D) ((weekNumber+=11));;
		F) ((weekNumber+=12));;
		G) ((weekNumber+=13));;
		H) ((weekNumber+=14));;
		K) ((weekNumber+=15));;
		L) ((weekNumber+=16));;
		M) ((weekNumber+=17));;
		N) ((weekNumber+=18));;
		P) ((weekNumber+=19));;
		Q) ((weekNumber+=20));;
		R) ((weekNumber+=21));;
		S) ((weekNumber+=22));;
		T) ((weekNumber+=23));;
		U) ((weekNumber+=24));;
		V) ((weekNumber+=25));;
		W) ((weekNumber+=26));;
		X) ((weekNumber+=27));;
		Y) ((weekNumber+=28));;
		*)
			echo "Error: Invalid serial number (reason: invalid week number)!"
			exit 128;;
	esac
fi

# Debug
if [ "$debug" == 1 ]; then
	echo "Week of manufacture (from serial number):" $weekNumber
fi

if [ "$MLBFormat" == 1 ]; then
	# Get the PP value (manufacture location) from the serial number
	PP=$(echo $SN | cut -c 1-2)

	# Get the SSSS value (production number) from the serial number
	SSSS=$(echo $SN | cut -c 6-8)

	# Generate a random (yet valid) CCCC value (model ID)
	BASE62=($(echo {0..9} {a..z} {A..Z}))
	partNumber=$(echo $(($RANDOM*7584284)) | cut -c 1-8)
	for i in $(bc <<< "obase=36; $partNumber"); do
		echo ${BASE62[$(( 10#$i ))]} | tr "\\n" "," | tr -d , >> tmpCCCC
	done
	CCCC=$(cat tmpCCCC | cut -c 1-4 | tr '[:lower:]' '[:upper:]')
	rm tmpCCCC
	# TODO: Base the CCCC off the model identifier in the 11-digit serial

	MLB=$PP$serialNumberYear$weekNumber"0"$SSSS$CCCC

	# Debug/Print MLB
	if [ "$debug" == 1 ]; then
		case "$PP" in
			F | FC | XA | XB | QP | G8) location="United States";;
			RN) location="Mexico";;
			CK) location="Ireland";;
			SE | E) location="Singapore";;
			MB) location-"Malaysia";;
			PT | CY) location="Korea";;
			EE | QT | UV) location="Taiwan";;
			1C | 4H | W8 | YM | VM | MQ | 7J) location="China";;
			RM) location="Refurbished/Remanufactured";;
		esac
		echo "Manufacture location (from serial number):" $location
		echo "Production number (from serial number):" $SSSS
		echo "Generated CCCC value:" $CCCC
		echo "Generated Main Logic Board (MLB) serial number:" $MLB "(13 characters)"
	else
		echo $MLB # Print the generated MLB value
	fi

elif [ "$MLBFormat" = 2 ]; then
	# Get the SSS value (manufacture location) from the serial number
	SSS=$(echo $SN | cut -c1-3)

	# Generate a random (yet valid) TTT value (board serial)
	declare -a TTTCodes=('200' '600' '403' '404' '405' '303' '108' '207' '609' '501' '306' '102' '701' '301' '501' '101' '300' '130' '100' '270' '310' '902' '104' '401' '902' '500' '700' '802')
	TTTIndex=$( jot -r 1  0 $((${#TTTCodes[@]} - 1)) )
	TTT=${TTTCodes[TTTIndex]}

	# Generate a random (yet valid) CC value
	declare -a CCCodes=('GU' '4N' 'J9' 'QX' 'OP' 'CD' 'GU')
	CCIndex=$( jot -r 1  0 $((${#CCCodes[@]} - 1)) )
	CC=${CCCodes[CCIndex]}

	# Generate a random (yet valid) EEEE value
	declare -a EEEECodes=('DYWF' 'F117' 'F502' 'F505' 'F9GY' 'F9H0' 'F9H1' 'F9H2' 'DYWD' 'F504' 'F116' 'F503' 'F2FR' 'F653' 'F49P' 'F651' 'F49R' 'F652' 'DYW3' 'F64V' 'F0V5' 'F64W' 'FF4G' 'FF4H' 'FF4J' 'FF4K' 'FF4L' 'FF4M' 'FF4N' 'FF4P' 'DNY3' 'DP00' 'DJWK' 'DM66' 'DNJK' 'DKG1' 'DM65' 'DNJJ' 'DKG2' 'DM67' 'DNJL' 'DJWM' 'DMT3' 'DMT5' 'DJWN' 'DM69' 'DJWP' 'DM6C')
	EEEEIndex=$( jot -r 1  0 $((${#EEEECodes[@]} - 1)) )
	EEEE=${EEEECodes[EEEEIndex]}

	# Generating a random (yet valid) KK value
	declare -a KKCodes=('1H' '1M' 'AD' '1F' 'A8' 'UE' 'JA' 'JC' '8C' 'CB' 'FB')
	KKIndex=$( jot -r 1  0 $((${#KKCodes[@]} - 1)) )
	KK=${KKCodes[KKIndex]}

	MLB=$SSS$manufactureYear$weekNumber$TTT$CC$EEEE$KK

	# Debug/Print MLB
	if [ "$debug" == 1 ]; then
		case "$SSS" in
			CK2) location="Cork, Ireland";;
			C02) location="Quanta Computer, China";;
		esac
		echo "Manufacture location (from serial number):" $location
		echo "Generated TTT value:" $TTT
		echo "Generated CC value:" $CC
		echo "Generated EEEE value:" $EEEE
		echo "Generated KK value:" $KK 
		echo "Generated Main Logic Board (MLB) serial number:" $MLB "(17 characters)"
	else
		echo $MLB # Print the generated MLB value
	fi
fi
