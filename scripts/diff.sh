#!/bin/bash
# Commands to check changes on the DB structure.
# Messages go through stderr, resulting script to stdout.
# example: ./diff.sh 2>/dev/null | tee update.sql | less

# Set the value of this variable to the name of the variable that points
# to the project's code base.
BASEDIR_VAR=CHARPDIR

# *** No further editing needed after this line. ***

BASEDIR=${!BASEDIR_VAR}

export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

if [ -z "$BASEDIR" ]; then
    echo "$BASEDIR_VAR is not defined." >&2
    exit 1
fi

if [ ! -d "$BASEDIR" ]; then
    echo "The value of \$$BASEDIR_VAR ($BASEDIR) does not point to a directory." >&2
    exit 3
fi

source "$BASEDIR/conf/config.sh"

cd $BASEDIR/scripts || exit

NEWDB=${PGDATABASE}_new_$RANDOM
    
(
    exec 1>&2

    $BASEDIR/scripts/initdb.sh -db $NEWDB -nocat
    
    "$PGBINDIR"pg_dump -s -f new.sql $NEWDB
    "$PGBINDIR"pg_dump -s -f prod.sql ${PGDATABASE}
    
    psql -d postgres -c "DROP DATABASE $NEWDB"
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
