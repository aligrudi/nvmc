#!/bin/sh
# Create an NVMC user
if test "$#" -lt 2; then
	echo "Usage: $0 username password"
	exit 1
fi

user="$1"
pass="$2"
group="users"
name=""

if test -d /home/$user; then
	echo "User $user already exists"
	exit 1
fi

useradd -d /home/$user -g $group -m -N -c "$name" -s /var/nc/nclogin $user
chmod 700 /home/$user
echo $user:$pass | chpasswd
