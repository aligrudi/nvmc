#!/bin/sh
# Create an NVMC virtual machine

# Default directories
NCDIR="/var/nc"
VMDIR="$NCDIR/vms"
HSDIR="$NCDIR/hosts"
MACPT="52:54:CC:5E:%02X:%02X"
# VM variables
mems="1"
cpus="1"
disk=""
user="root"
name=""
host="host1"
temp="ubuntu16"
gpu=""
iso=""
net=""
cln=""

printusage() {
	echo "Usage: $0 options"
	echo
	echo "Options:"
	echo "  -n name    VM name"
	echo "  -u user    VM owner"
	echo "  -c cpus    CPU count"
	echo "  -m mem     memory size (GB)"
	echo "  -d size    disk size (GB)"
	echo "  -h host    VM host"
	echo "  -t disk    disk image (blank, ubuntu16, ubuntu18, windows10, ubuntu18-cuda)"
	echo "  -i iso     CD/DVD ISO"
	echo "  -g gpu#    GPU number to passthrough (1, 2)"
	echo "  -net x     NIC type (b: bridge, u: slirp)"
	echo "  -cln x     disk image clone type (c: copy, o: overlay)"
}

if test "$#" = "0"; then
	printusage
	exit
fi

while test "$#" -ge 1; do
	case "$1" in
		-c)
			cpus="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-m)
			mems="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-d)
			disk="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-n)
			name="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-u)
			user="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-h)
			host="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-t)
			temp="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-i)
			iso="$iso $2"
			shift && test "$#" -ge 1 && shift
			;;
		-g)
			gpu="$gpu $2"
			shift && test "$#" -ge 1 && shift
			;;
		-net)
			net="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-cln)
			cln="$2"
			shift && test "$#" -ge 1 && shift
			;;
		*)
			printusage
			exit 1
			;;
	esac
done

if test -z "$name"; then
	echo "VM name cannot be empty"
	exit 1
fi
vm="$VMDIR/$name"
if test -d $vm; then
	echo "Directory <$vm> already exists"
	exit 1
fi
if test ! -d "$HSDIR/$host"; then
	echo "Unknown host <$host>"
	exit 1
fi
if ! id $user >/dev/null 2>&1; then
	echo "Unknown user <$user>"
	exit 1
fi

# Create VM directory and files
mkdir -p $vm
echo $cpus >$vm/CPUS
echo $mems >$vm/MEMS
echo $disk >$vm/DISK
id -u $user >$vm/USER
echo $host >$vm/HOST
echo "10" >$vm/DISK
test "$temp" = "windows10" && echo 30 >$vm/DISK

# Adding Qemu options
for x in $iso; do
	echo "-drive file=$NCDIR/imgs/$x,format=raw,readonly=on,media=cdrom" >>$vm/OPTS
done
for x in $gpu; do
	test "$x" = "1" && echo "-device vfio-pci,host=0b:00.1 -device vfio-pci,host=0b:00.2 -device vfio-pci,host=0b:00.0 -device vfio-pci,host=0b:00.3" >>$vm/OPTS
	test "$x" = "2" && echo "-device vfio-pci,host=84:00.1 -device vfio-pci,host=84:00.2 -device vfio-pci,host=84:00.0 -device vfio-pci,host=84:00.3" >>$vm/OPTS
done

# Create INIT script
echo "#!/bin/sh" >$vm/INIT
echo "test -f disk && exit" >>$vm/INIT
if test -z "$cln" -o "$cln" = "c"; then
	echo "cp $NCDIR/imgs/$temp.img disk" >>$vm/INIT
else
	echo "qemu-img create -f qcow2 -b $NCDIR/imgs/$temp.img disk" >>$vm/INIT
fi
chmod +x $vm/INIT
if test -n "$disk"; then
	if test "$disk" -gt "`cat $vm/DISK`"; then
		echo "#!/bin/sh" >$vm/ONCE
		echo "qemu-img resize disk ${disk}G" >>$vm/ONCE
		chmod +x $vm/ONCE
		echo $disk >$vm/DISK
	fi
fi

# VM information
echo "VM name         $name"
echo "VM memory size  $mems"
echo "VM cpu count    $cpus"
echo "VM owner        $user"
echo "VM host         $host"

# Start the VM
if ! nc push $name; then
	echo "Retry <nc push $name> later"
	exit 1
fi
slot="`cat $vm/SLOT`"
echo "VM slot         $slot"

# Assign a MAC address (for bridged networking)
if test -z "$net" -o "$net" = "b"; then
	printf "$MACPT\\n" "`expr $slot / 256`" "`expr $slot % 256`" >$vm/EMAC
	emac="`cat $vm/EMAC`"
	echo "VM mac address  $emac"
	nc push $name
fi
