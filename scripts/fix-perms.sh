#!/bin/bash
# Fix file permissions for cygwin.

# Fix group being assigned to "Ninguno", otherwise group permissions can't be set.
chgrp -R Usuarios .

rnd=/tmp/fix-perms-$RANDOM

# Using file descriptors is not mode-agnostic, but it's faster.
exec 3>$rnd.644
exec 4>$rnd.755

git ls-tree -r HEAD | while read i; do 
    mode=${i:3:3}
    file=${i:52}
    if [ $mode = 644 ]; then echo -ne $file'\0' >&3
    elif [ $mode = 755 ]; then echo -ne $file'\0' >&4
    fi
done

# Close file descriptors.
3>&-
4>&-

ls ${rnd}* | while read i; do
    mode=$(cut -f2 -d. <<< $i)
    xargs -0 -a $i chmod $mode 
done

rm -f ${rnd}*

# These are required to secure mysql passwords.
chmod -f 600 mysql/conf/my.cnf
chmod -f 600 mysql/conf/my-su.cnf
