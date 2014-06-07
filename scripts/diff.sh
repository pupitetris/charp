#!/bin/bash

# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Commands to check changes on the DB structure.
# Messages go through stderr, resulting script to stdout.
# example: ./diff.sh 2>/dev/null | tee update.sql | less

# For debugging:
#set -x

# Set the value of this variable to the name of the variable that points
# to the project's code base.
BASEDIR_VAR=CHARP_DIR

# Set the locale you want the script to run under (comment for system default).
export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

# *** No further editing needed after this line. ***

BASEDIR=${!BASEDIR_VAR}
if [ -z "$BASEDIR" ]; then
    echo "$BASEDIR_VAR is not defined." >&2
    exit 1
fi
if [ ! -d "$BASEDIR" ]; then
    echo "The value of \$$BASEDIR_VAR ($BASEDIR) does not point to a directory." >&2
    exit 3
fi

source "$BASEDIR"/conf/config.sh

cd $BASEDIR/scripts || exit

NEWDB=${DB_DATABASE}_new_$RANDOM
    
(
    exec 1>&2

    ./initdb.sh -db $NEWDB -nocat
    
    "$PGBINDIR"pg_dump -s -f new.sql $NEWDB
    "$PGBINDIR"pg_dump -s -f prod.sql ${PGDATABASE}
    
    psql -q -d postgres -c "DROP DATABASE $NEWDB"
)

# http://apgdiff.startnet.biz/how_to_use_it.php
java -jar bin/apgdiff.jar --ignore-start-with prod.sql new.sql > $NEWDB

rm -f prod.sql new.sql

if [ $(wc -c < $NEWDB) != 0 ]; then
    echo 'BEGIN TRANSACTION;'
    cat $NEWDB
    echo $'\nCOMMIT TRANSACTION;'
fi

rm -f $NEWDB
