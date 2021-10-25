#!/usr/bin/bash

# USER SETTABLE:

# L4T/Jetpack version:
RVERSION='32'
VERSION='6.1'
MODULETYPE='NanoEMMC'
REV='rev1.0'

# DO NOT EDIT BELOW THIS LINE
# ==================================================

# Fix for Nvidia bad path on server
EXTRA_PATH=''
if [ "$VERSION" == "5.1" ]; then
	EXTRA_PATH=/r${RVERSION}_release_v${VERSION}
fi


SCRIPTDIR=$(pwd)/

BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
YELLOW='\033[1;33m'

SC=$WHITE	#Fat text color
HC=$GREEN	#Highlight color
LC=$YELLOW	#Link/command color
EC=$RED		#Error color
IC=$BLUE        #Inconspicuous color
NC='\033[0m'	#Terminal default color

function step_echo () {
	echo -e "${HC}=== $1 ===${IC}"
}

function checked_run () {
	COMMAND=$1
	echo -e "${LC}${COMMAND}${NC}"
	HASH=`echo "$COMMAND" | md5sum | cut -d " " -f1`
	if [ -f $HASH ]; then
		echo -e "${HC}Step already completed in a previous run, skipping...${NC}"
	else
		$COMMAND
		RESULT=$?
		if [ $RESULT -ne 0 ]; then
			echo -e "${EC}Command: $COMMAND has failed with code $RESULT. Aborting.${NC}"
			exit
		else
			echo -e "${SC}Command succesfully completed${NC}"
			touch $HASH
		fi
	fi
}

echo "==========================================================================="
echo -e "${HC} Take-Air Open.OC2 firmware installer"
echo ""
echo -e " ${HC}NOTE:${SC} Remove the openoc2-firmware-work/ directory if you want to reset the process (requires sudo)"
echo ""
echo -e "--"
echo ""
step_echo "READY TO START!"


mkdir openoc2-firmware-work
pushd openoc2-firmware-work/



step_echo "STEP 1: Download L4T"
checked_run "wget ""https://developer.nvidia.com/embedded/l4t/r${RVERSION}_release_v${VERSION}/t210/jetson-210_linux_r${RVERSION}.${VERSION}_aarch64.tbz2"""


step_echo "STEP 2: Download sample root file system"
checked_run "wget ""https://developer.nvidia.com/embedded/l4t/r${RVERSION}_release_v${VERSION}/t210/tegra_linux_sample-root-filesystem_r${RVERSION}.${VERSION}_aarch64.tbz2"""



step_echo "STEP 3: Extract to img"
mkdir img
pushd img
checked_run "tar -xjf ../jetson-210_linux_r${RVERSION}.${VERSION}_aarch64.tbz2"
popd

step_echo "STEP 4: Extract sample FS (requires sudo password)"
pushd img/Linux_for_Tegra/rootfs
checked_run "sudo tar -jxpf ../../../tegra_linux_sample-root-filesystem_r${RVERSION}.${VERSION}_aarch64.tbz2"
popd



step_echo "STEP 5a: Get custom kernel and device tree"
checked_run "wget ""https://github.com/TakeAirRobotics/OpenOC2_firmware_install/raw/master/OpenOC2_TA_customKernelDTB_${REV}_${MODULETYPE}_${RVERSION}.${VERSION}.tar.xz"""

step_echo "STEP 5b: Extract custom kernel and device tree"
checked_run "tar -xf OpenOC2_TA_customKernelDTB_${REV}_${MODULETYPE}_${RVERSION}.${VERSION}.tar.xz"

step_echo "STEP 5c: Copy custom device tree to img"
checked_run "cp -r tegra210-p3448-0002-p3449-0000-b00.dtb img/Linux_for_Tegra/kernel/dtb" #tegra210-p3448-0002-p3449-0000-b00.dtb img/Linux_for_Tegra/kernel/dtb"

step_echo "STEP 5d: Copy custom kernel to img"
checked_run 'cp Image img/Linux_for_Tegra/kernel'

step_echo "STEP 5e: Add version/revision numbering file to img (requires sudo password)"
sudo touch img/Linux_for_Tegra/rootfs/boot/OpenOC_version.txt
sudo echo "Take-Air Open.OC 2 kernel&Device Tree ${REV} for Jetson ${MODULETYPE}. Platform: L4T ${RVERSION}.${VERSION}." > img/Linux_for_Tegra/rootfs/boot/OpenOC_version.txt


step_echo "STEP 6: Generate and apply binaries (requires sudo password)"
pushd img
pushd Linux_for_Tegra
checked_run "sudo ./apply_binaries.sh"
popd
popd



step_echo "STEP 7: Flash the Jetson (requires sudo password)"
read -p "Connect a Jetson in recovery mode over USB and press Enter to start flashing" <&1
pushd img/Linux_for_Tegra
sudo ./flash.sh jetson-nano-emmc mmcblk0p1
popd


step_echo "=== Done ==="
