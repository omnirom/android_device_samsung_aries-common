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

# this creates n zram devices: /dev/block/zram{0,1,2,3}
ndevices=2

# set max number of compression streams
# compression backend may use up to max_comp_streams compression streams,
# thus allowing up to max_comp_streams concurrent compression operations.
# by default, compression backend uses single compression stream.
#
nstreams=1

# select compression algorithm
# using comp_algorithm device attribute one can see available and
# currently selected (shown in square brackets) compression algortithms,
# change selected compression algorithm (once the device is initialised
# there is no way to change compression algorithm).
# options: "lzo" or "lz4"
#
compress=lz4

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

# loading zram module
echo "loading zram module"
modprobe zram num_devices=${ndevices}

x=0
y=${ndevices}-1
while [ ${x} -le ${y} ]
do
    # compress algorithm
    echo ${compress} > /sys/block/zram${x}/comp_algorithm

    # disksize
    echo ${disksize} > /sys/block/zram${x}/disksize

    # streams
    echo ${nstreams} > /sys/block/zram${x}/max_comp_streams

    # creating and mounting zram partition(s)
    mkswap /dev/block/zram${x}
    swapon /dev/block/zram${x}

    x=$(( $x + 1 ))
done
