#!/bin/bash
# Comandos para comparar cambios en la BD.
# Mensajes por stderr, script resultante de la comparación por stdout
# por ejemplo: ./diff.sh 2>/dev/null | tee update.sql | less

BASEDIR="$BITADIR"

export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

DO_CLEAN=0

if [ "$1" = "-clean" ]; then
    DO_CLEAN=1
fi

if [ -z "$BASEDIR" ]; then
    echo 'La variable BASEDIR no está definida.' >&2
    exit 1
fi

if [ ! -d "$BASEDIR" ]; then
    echo "El valor de \$BASEDIR ($BASEDIR) no apunta a un directorio." >&2
    exit 3
fi

source "$BASEDIR/conf/config.sh"

cd $BASEDIR/scripts || exit

if [ $(uname -o) = 'Cygwin' ]; then
    PGBINDIR="/cygdrive/d/Program Files/PostgreSQL/9.0/bin/"
fi

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
