#!/bin/sh
#
# NVMC: Neat VM Cluster
#
# Copyright (C) 2020 Ali Gholami Rudi <ali at rudi dot ir>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Directories
NCDIR="/var/nc"
VMDIR="$NCDIR/vms"
HSDIR="$NCDIR/hosts"
HSBIN="$NCDIR"

# SSH and SCP options
SSH="ssh -q -o ConnectTimeout=2 -o ConnectionAttempts=1"
SCP="scp -q -o ConnectTimeout=2 -o ConnectionAttempts=1"

nchostinit() {
	host="*"
	if test "$#" -ge "2"; then
		host="$2"
	fi
	for h in $HSDIR/$host; do
		addr="`cat $h/ADDR`"
		echo "Updating `basename $h` ($addr)"
		$SSH $addr mkdir -p $HSBIN
		$SSH $addr mkdir -p $VMDIR
		$SCP $HSBIN/ncvm $HSBIN/QEMU $addr:$HSBIN/
	done
}

ncstat() {
	for vm in $VMDIR/*/; do
		if test -f $vm/CPUS -a -f $vm/MEMS; then
			vmname="`basename $vm`"
			stat="-"
			host="-"
			slot="-"
			disk="0"
			cpus="`cat $vm/CPUS`"
			mems="`cat $vm/MEMS`"
			test -f $vm/DISK && disk="`cat $vm/DISK`"
			test -f $vm/STAT && stat="`ncvm stat $vmname`"
			test -f $vm/SAVE && stat="saved"
			test -f $vm/HOST && host="`cat $vm/HOST`"
			test -f $vm/SLOT && slot="`cat $vm/SLOT`"
			printf "%03d  %-16s  %02d:%03d:%03d  %-8s  %-16s\\n" \
				"$slot" "`basename $vm`" "$cpus" "$mems" "$disk" "$host" "$stat"
		fi
	done
}

nchost_usedcpus() {
	host="$1"
	cnt="0"
	for vm in $VMDIR/*; do
		if test -f "$vm/STAT"; then
			if test -f "$vm/HOST" && test "`cat $vm/HOST`" = "$host"; then
				cur="`cat $vm/CPUS`"
				cnt="`expr $cnt + $cur`"
			fi
		fi
	done
	echo $cnt
}

nchost_usedmems() {
	host="$1"
	cnt="0"
	for vm in $VMDIR/*; do
		if test -f "$vm/STAT"; then
			if test -f "$vm/HOST" && test "`cat $vm/HOST`" = "$host"; then
				cur="`cat $vm/MEMS`"
				cnt="`expr $cnt + $cur`"
			fi
		fi
	done
	echo $cnt
}

nchost() {
	for h in $HSDIR/*/; do
		host=`basename $h`
		cpus=`nchost_usedcpus $host`
		mems=`nchost_usedmems $host`
		echo "$host	`cat $h/ADDR`	$cpus/`cat $h/CPUS`	$mems/`cat $h/MEMS`"
	done
}

ncslot_find() {
	slots="$NCDIR/.slots"
	test -f $slots || seq 0 512 >$slots
	cp $slots $slots.$$
	for v in $VMDIR/*; do
		if test -f $v/SLOT; then
			cur="`cat $v/SLOT`"
			sed "/^$cur\$/d" <$slots.$$ >$slots.$$.1
			mv $slots.$$.1 $slots.$$
		fi
	done
	head -n1 <$slots.$$
	rm $slots.$$
}

ncvmcheck() {
	vm="$1"
	if test -z "$vm"; then
		echo "nc: VM name is missing"
		return 1
	fi
	if test ! -d "$VMDIR/$vm"; then
		echo "nc: directory $VMDIR/$vm does not exist"
		return 1
	fi
	if test ! -f "$VMDIR/$vm/HOST"; then
		echo "nc: $VMDIR/$vm/HOST is missing"
		return 1
	fi
}

ncpush() {
	vm="$2"
	ncvmcheck $vm || return 1
	if test ! -f $VMDIR/$vm/SLOT; then
		ncslot_find >$VMDIR/$vm/SLOT
	fi
	host="`cat $VMDIR/$vm/HOST`"
	addr="`cat $HSDIR/$host/ADDR`"
	if $SCP -r $VMDIR/$vm $addr:$VMDIR/; then
		if test ! -f $VMDIR/$vm/STAT; then
			if ncvm init $vm; then
				echo "OK" >$VMDIR/$vm/STAT
			else
				echo "nc: cannot initialize VM $vm on $host"
				return 1
			fi
		fi
	else
		echo "nc: host $host does not respond"
		return 1
	fi
}

ncsize() {
	vm="$2"
	size="$3"
	ncvmcheck $vm || return 1
	if test -z "$size"; then
		echo "nc: image name is missing"
		return 1
	fi
	if test -f $VMDIR/$vm/DISK && test "$size" -le "`cat $VMDIR/$vm/DISK`"; then
		echo "nc: cannot shrink VM disk"
		return 1
	fi
	if test ! -x "$VMDIR/$vm/ONCE"; then
		echo "#!/bin/sh" >$VMDIR/$vm/ONCE
		chmod +x $VMDIR/$vm/ONCE
	fi
	echo "qemu-img snapshot -d nvmc0 disk" >>$VMDIR/$vm/ONCE
	echo "qemu-img resize disk ${size}G" >>$VMDIR/$vm/ONCE
	echo "$size" >$VMDIR/$vm/DISK
}

ncvm() {
	cmd="$1"
	vm="$2"
	ncvmcheck $vm || return 1
	shift 2
	host="`cat $VMDIR/$vm/HOST`"
	addr="`cat $HSDIR/$host/ADDR`"
	$SSH $addr $HSBIN/ncvm $VMDIR/$vm $cmd $*
}

ncexec() {
	cmd="$1"
	vm="$2"
	ncvmcheck $vm || return 1
	shift 2
	host="`cat $VMDIR/$vm/HOST`"
	addr="`cat $HSDIR/$host/ADDR`"
	test -f $VMDIR/$vm/SAVE && opts="-loadvm `cat $VMDIR/$vm/SAVE`"
	if ! $SSH $addr sh -c "\"nohup $HSBIN/ncvm $VMDIR/$vm exec $opts 0</dev/null 1>/dev/null 2>&1 &\""; then
		echo "nc: failed to start the VM"
		return 1
	fi
	test -f $VMDIR/$vm/ONCE && rm $VMDIR/$vm/ONCE
	test -f $VMDIR/$vm/SAVE && rm $VMDIR/$vm/SAVE
}

ncname() {
	vm="$2"
	name="$3"
	ncvmcheck $vm || return 1
	if test -z "$name"; then
		echo "nc: new VM name is missing"
		return 1
	fi
	if test -d "$VMDIR/$name"; then
		echo "nc: directory $VMDIR/$vm already exists"
		return 1
	fi
	if test -f $VMDIR/$vm/HOST -a -f $VMDIR/$vm/STAT; then
		host="`cat $VMDIR/$vm/HOST`"
		addr="`cat $HSDIR/$host/ADDR`"
		if test "`ncvm stat $vm`" != "off"; then
			echo "nc: VM $vm should be off to rename"
			return 1
		fi
		if ! $SSH $addr mv $VMDIR/$vm $VMDIR/$name; then
			echo "nc: failed to rename VM $vm on $host"
			return 1
		fi
	fi
	mv $VMDIR/$vm $VMDIR/$name
	echo "nc: renamed VM $vm to $name"
}

ncdrop() {
	vm="$2"
	ncvmcheck "$vm" || return 1
	if test -f $VMDIR/$vm/HOST -a -f $VMDIR/$vm/STAT; then
		host="`cat $VMDIR/$vm/HOST`"
		addr="`cat $HSDIR/$host/ADDR`"
		if test "`ncvm stat $vm`" != "off"; then
			echo "nc: VM $vm should be off to drop"
			return 1
		fi
		if ! $SSH $addr rm -r $VMDIR/$vm; then
			echo "nc: failed to remove VM $vm on $host"
			return 1
		fi
	fi
	rm -r $VMDIR/$vm
	echo "nc: removed VM $vm"
}

ncsshs() {
	vm="$2"
	sock="$3"
	ncvmcheck $vm || return 1
	if test -z "$sock"; then
		echo "nc: socket address is missing"
		return 1
	fi
	if test -S "$sock"; then
		fuser "$sock" >/dev/null 2>&1 && kill `fuser $sock 2>/dev/null`
		rm "$sock"
	fi
	# Turn on the VM if it is not
	ncexec exec "$vm" >/dev/null 2>&1
	# Forward SSH connections
	host="`cat $VMDIR/$vm/HOST`"
	addr="`cat $HSDIR/$host/ADDR`"
	slot="`cat $VMDIR/$vm/SLOT`"
	port="`expr 2200 + $slot`"
	$SSH -f -L $sock:127.0.0.1:$port $addr sleep 12h
	chmod o+rw $sock
}

ncvncs() {
	vm="$2"
	sock="$3"
	ncvmcheck $vm || return 1
	if test -z "$sock"; then
		echo "nc: socket address is missing"
		return 1
	fi
	if test -S "$sock"; then
		fuser "$sock" >/dev/null 2>&1 && kill `fuser $sock 2>/dev/null`
		rm "$sock"
	fi
	# Turn on the VM if it is not
	ncexec exec "$vm" >/dev/null 2>&1
	# Forward VNC connections
	host="`cat $VMDIR/$vm/HOST`"
	addr="`cat $HSDIR/$host/ADDR`"
	slot="`cat $VMDIR/$vm/SLOT`"
	$SSH -f -L $sock:$VMDIR/$vm/qemu.vnc $addr sleep 3h
	sleep .5
	chmod o+rw $sock
}

ncsave() {
	vm="$2"
	ncvmcheck $vm || return 1
	if test "`ncvm stat $vm`" != "running"; then
		echo "nc: VM $vm should be running to save"
		return 1
	fi
	ncvm stop $vm
	if ! ncvm save $vm nvmc0; then
		echo "nc: failed to save VM $vm"
		ncvm cont $vm
		return 1
	fi
	ncvm quit $vm
	echo nvmc0 >$VMDIR/$vm/SAVE
}

echo "`date '+%Y:%m:%d %T'`	$*" >>$NCDIR/nc.log

# Main commands
case "$1" in
	host)
		nchost $* || exit 1
		;;
	hostinit)
		nchostinit $* || exit 1
		;;
	stat|vm)
		ncstat $* || exit 1
		;;
	push)
		ncpush $* || exit 1
		;;
	vncs)
		ncvncs $* || exit 1
		;;
	sshs)
		ncsshs $* || exit 1
		;;
	dist)
		ncdist $* || exit 1
		;;
	disk)
		ncdisk $* || exit 1
		;;
	size)
		ncsize $* || exit 1
		;;
	exec)
		ncexec $* || exit 1
		;;
	name)
		ncname $* || exit 1
		;;
	drop)
		ncdrop $* || exit 1
		;;
	save)
		ncsave $* || exit 1
		;;
	stop|cont|quit|reboot|send|kill|poff|qlog)
		ncvm $* || exit 1
		;;
	*)
		echo "Usage: $0 command [options]"
		echo
		echo "Available commands:"
		echo "  host      show hosts"
		echo "  stat      show VMs"
		echo "  push      send a VM to host or update its files"
		echo "  name      rename a VM"
		echo "  drop      remove a VM"
		echo "  size      change VM's disk size"
		echo "  vncs      forward VNC connections to a VM"
		echo "  sshs      forward SSH connections to a VM"
		echo "  save      save VM state and stop VM"
		echo "  hostinit  install or update NVMC on host nodes"
		echo
		echo "Available commands for managing VMs:"
		echo "  exec      start qemu"
		echo "  quit      exit qemu"
		echo "  poff      send poweroff signal"
		echo "  reboot    send reboot signal"
		echo "  stop      stop the VM"
		echo "  cont      continue the VM"
		echo "  qlog      show qemu logs"
		;;
esac
