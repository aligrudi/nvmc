#!/bin/sh
# Create a backup from /var/nc/
name="nvmc`date '+%Y%m%d%H%M%S'`"

cp -r /var/nc $name
tar czf $name.tar.gz $name
rm -r "$name"
