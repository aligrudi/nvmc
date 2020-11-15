#!/bin/sh
# Create a tunnel to an NVMC VM
host="hpc.nit.ac.ir"
user="user"
port="5909"
vm=""
cmd="ncvnc"

printusage() {
	echo "Usage: $0 options"
	echo
	echo "Options:"
	echo "  -u user    username"
	echo "  -p port    port to forward"
	echo "  -n name    VM name"
	echo "  -h host    hostname"
	echo "  -ssh       forward SSH connections"
	echo "  -vnc       forward VNC connections"
	echo "  -passwd    change password"
}

if test "$#" = "0"; then
	printusage
	exit
fi

while test "$#" -ge 1; do
	case "$1" in
		-n)
			vm="$2"
			shift && test "$#" -ge 1 && shift
			;;
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
		-ssh)
			cmd="ncssh"
			shift
			;;
		-vnc)
			cmd="ncvnc"
			shift
			;;
		-passwd)
			cmd="passwd"
			shift
			;;
		*)
			printusage
			exit 1
			;;
	esac
done
ssh -L $port:/home/$user/$vm.vnc $user@$host $cmd $vm
