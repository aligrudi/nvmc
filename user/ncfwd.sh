#!/bin/sh
# Create a tunnel to an NVMC VM
host="hpc.nit.ac.ir"
user="user"
port="5909"
sshport="0"
rdpport="0"
vm=""
ip=""
cmd=""

echo "NVMC Client Connection"
echo

printusage() {
	echo "Usage: $0 options"
	echo
	echo "Options:"
	echo "  -h host     host name ($host)"
	echo "  -u user     user name"
	echo "  -n vmname   VM name"
	echo "  -i vmaddr   VM local IP address"
	echo "  -vnc port   VNC local port ($port)"
	echo "  -ssh port   SSH local port ($sshport)"
	echo "  -rdp port   RDP local port ($rdpport)"
}

# Read options
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
		-n)
			vm="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-i)
			ip="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-h)
			host="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-vnc)
			port="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-ssh)
			sshport="$2"
			shift && test "$#" -ge 1 && shift
			;;
		-rdp)
			rdpport="$2"
			shift && test "$#" -ge 1 && shift
			;;
		*)
			printusage
			exit 1
			;;
	esac
done
if test -z "$vm$ip"; then
	printusage
	exit 1
fi

# Forward connections
test "0$port" -gt "0" && vncopts="-L $port:/home/$user/$vm.vnc"
test "0$sshport" -gt "0" && sshopts="-L $sshport:$ip:22"
test "0$rdpport" -gt "0" && rdpopts="-L $rdpport:$ip:3389"
ssh $vncopts $sshopts $rdpopts $user@$host ncuser vncs $vm
