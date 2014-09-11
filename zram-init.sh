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

# this creates n zram devices: /dev/block/zram{0,1,2,3}
# default value is 1
#
ndevices=1
if busybox test -e ${ZRAM_PATH}/num_devices ; then
    ndevices=`busybox cat ${ZRAM_PATH}/num_devices`
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
disksize="128M"
if busybox test -e ${ZRAM_PATH}/disksize ; then
    disksize=`busybox cat ${ZRAM_PATH}/disksize`
else
    busybox echo ${disksize} > ${ZRAM_PATH}/disksize
fi
busybox echo "disksize: ${disksize}"

# loading zram module
#
busybox echo "loading zram module"
modprobe zram num_devices=${ndevices}
busybox echo ""

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
