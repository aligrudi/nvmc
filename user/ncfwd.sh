#!/bin/sh
# Create a tunnel to an NVMC VM
host="hpc.nit.ac.ir"
user="user"
port="5909"
vm=""
ip=""
cmd="type"

printusage() {
	echo "Usage: $0 options"
	echo
	echo "Options:"
	echo "  -u user    username"
	echo "  -p port    port to forward"
	echo "  -h host    hostname"
	echo "  -vnc vm    forward VNC connections"
	echo "  -ssh ip    forward SSH connections"
	echo "  -rdp ip    forward RDP connections"
}

if test "$#" = "0"; then
	printusage
	exit
fi

while test "$#" -ge 1; do
	case "$1" in
		-u)
			user="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-p)
			port="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-h)
			host="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-vnc)
			cmd="vnc"
			vm="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-ssh)
			cmd="ssh"
			ip="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-rdp)
			cmd="rdp"
			ip="$2"
			shift && test "$#" -ge 1 && shift
			;;
		*)
			printusage
			exit 1
			;;
	esac
done
if test -z "$cmd"; then
	printusage
	exit 1
fi
test "$cmd" = "vnc" && ssh -L $port:/home/$user/$vm.vnc $user@$host $cmd $vm
test "$cmd" = "ssh" && ssh -N -L $port:$ip:22 $user@$host
test "$cmd" = "rdp" && ssh -N -L $port:$ip:3389 $user@$host
