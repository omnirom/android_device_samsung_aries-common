#!/system/bin/sh
#
# Copyright (C) 2014 OmniROM Project
#
# Author: Humberto Borba <humberos@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
PATH=/system/bin/:/system/xbin/

ZRAM_PATH=/data/misc/zram
ZRAM_IS_DISABLED=0

# logging
#
set_log() {
    rm -rf $1
    exec >> $1 2>&1
}

mkdir -p ${ZRAM_PATH}
set_log ${ZRAM_PATH}/init.log

# this creates n zram devices: /dev/block/zram{0,1,2,3,4}
# default value is 1
#
ndevices=1
if busybox test -e ${ZRAM_PATH}/num_devices ; then
    ndevices=`busybox cat ${ZRAM_PATH}/num_devices`
    case ${ndevices} in
        0|1|2|3|4)
        ;;
        *)
            busybox echo "error: invalid num_device value[0,1,2,3,4]: ${ndevices}"
            busybox echo "error: setting default value"
            busybox echo 1 > ${ZRAM_PATH}/num_devices
            ndevices=1
        ;;
    esac
else
    busybox echo ${ndevices} > ${ZRAM_PATH}/num_devices
fi
busybox echo "num_devices: ${ndevices}"

# this disables zram swap
# if the num_devices param = 0
#
if [ ${ndevices} -eq ${ZRAM_IS_DISABLED} ] ; then
    busybox echo "zram was disabled"
    exit 1
fi

# set max number of compression streams
# compression backend may use up to max_comp_streams compression streams,
# thus allowing up to max_comp_streams concurrent compression operations.
# by default, compression backend uses single compression stream.
#
nstreams=1
if busybox test -e ${ZRAM_PATH}/max_comp_streams ; then
    nstreams=`busybox cat ${ZRAM_PATH}/max_comp_streams`
    case ${nstreams} in
        1|2|3|4)
        ;;
        *)
            busybox echo "error: invalid number of streams value[1,2,3,4]: ${nstreams}"
            busybox echo "error: setting default value"
            busybox echo 1 > ${ZRAM_PATH}/max_comp_streams
            nstreams=1
        ;;
    esac
else
    busybox echo ${nstreams} > ${ZRAM_PATH}/max_comp_streams
fi
busybox echo "compression streams: ${nstreams}"

# select compression algorithm
# using comp_algorithm device attribute one can see available and
# currently selected (shown in square brackets) compression algortithms,
# change selected compression algorithm (once the device is initialised
# there is no way to change compression algorithm).
# options: "lzo" or "lz4"
#
compress=lzo
if busybox test -e ${ZRAM_PATH}/comp_algorithm ; then
    compress=`busybox cat ${ZRAM_PATH}/comp_algorithm`
    case ${compress} in
        lzo|lz4)
        ;;
        *)
            busybox echo "error: invalid compression algorithm value[lzo,lz4]: ${compress}"
            busybox echo "error: setting default value"
            busybox echo "lzo" > ${ZRAM_PATH}/comp_algorithm
            compress=lzo
        ;;
    esac
else
    busybox echo ${compress} > ${ZRAM_PATH}/comp_algorithm
fi
busybox echo "compression algorithm: ${compress}"

# set disksize
# writing the value to sysfs node 'disksize'.
# the value can be either in bytes or you can use mem suffixes.
#
#  examples:
#
#    initialize /dev/zram0 with 50MB disksize
#
#    echo $((50*1024*1024)) > /sys/block/zram0/disksize
#
#    using mem suffixes
#
#       echo 256K > /sys/block/zram0/disksize
#       echo 512M > /sys/block/zram0/disksize
#       echo 1G > /sys/block/zram0/disksize
#
#    for aries and p1 devices, only these options below
#
#        64M - can be set for 4 devices: total 256M
#       128M - can be set for 4 devices: total 512M
#       256M - can be set for 1 or 2 zram devices, total 512M
#       512M - can be set only for 1 zram device
#              this is max setup at moment
#              aries and p1 devices have 512M of total ram memory (1:1)
#
disksize="128M"
if busybox test -e ${ZRAM_PATH}/disksize ; then
    disksize=`busybox cat ${ZRAM_PATH}/disksize`
    case ${disksize} in
        "32M"|"64M"|"128M")
        ;;
        "256M")
            case ${ndevices} in
                1|2)
                ;;
                3|4)
                    busybox echo "error: invalid 256M setup: ${ndevices}"
                    busybox echo 2 > ${ZRAM_PATH}/num_devices
                    ndevices=2
                    busybox echo "warning: new entry for num_device: ${ndevices}"
                ;;
                *)
                    busybox echo "error: invalid size: ${ndevices}"
                    busybox echo 1 > ${ZRAM_PATH}/num_devices
                    ndevices=1
                    busybox echo "warning: new entry for num_device: ${ndevices}"
                ;;
            esac
        ;;
        "512M")
            case ${ndevices} in
                1)
                ;;
                *)
                    busybox echo "error: invalid 512M setup: ${ndevices}"
                    busybox echo 1 > ${ZRAM_PATH}/num_devices
                    ndevices=1
                    busybox echo "warning: new entry for num_device: ${ndevices}"
                ;;
            esac
        ;;
        *)
            busybox echo "error: invalid disksize [64,128,256,512M]: ${disksize}"
            busybox echo "error: setting default value"
            busybox echo "128M" > ${ZRAM_PATH}/disksize
            disksize="128M"
        ;;
    esac
else
    busybox echo ${disksize} > ${ZRAM_PATH}/disksize
fi
busybox echo "disksize: ${disksize}"

# loading zram module
#
busybox echo "loading zram module"
modprobe zram num_devices=${ndevices}
busybox echo ""

# writing zram values for each device
#
x=0
y=${ndevices}-1

while [ ${x} -le ${y} ]
do
#   streams
    busybox echo ${nstreams} > /sys/block/zram${x}/max_comp_streams

#   compress algorithm
    busybox echo ${compress} > /sys/block/zram${x}/comp_algorithm

#   disksize
    busybox echo ${disksize} > /sys/block/zram${x}/disksize

#   creating and mounting zram partition(s)
    mkswap /dev/block/zram${x}
    busybox echo ">>>> mkswap /dev/block/zram${x}"
    swapon /dev/block/zram${x}
    busybox echo ">>>> swapon /dev/block/zram${x}"
    busybox echo ""
    x=$(( $x + 1 ))
done

exit 0
