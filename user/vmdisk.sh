#!/bin/sh
# Extend partition in an NVMC VM
disk="/dev/vda"
if test "$#" -gt 0; then
	disk="$1"
fi
if test ! -e "$disk"; then
	echo "Disk $disk does not exist."
	exit 1
fi
# Create a large partition
echo ";" | sfdisk -f $disk
# Reread partition table
if ! partx -u $disk; then
	echo 1 >/sys/block/$disk/device/rescan
fi
# Resize the file system
resize2fs ${disk}1
