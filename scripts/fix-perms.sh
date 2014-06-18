#!/bin/bash

chgrp -R Usuarios .

git ls-tree -r HEAD | while read i; do 
    mode=$(cut -c4-6 <<< $i)
    file=$(cut -f4 -d$' ' <<< $i)
    chmod $mode "$file"
done

chmod 600 mysql/conf/my.cnf
chmod 600 mysql/conf/my-su.cnf
