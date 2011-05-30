#!/bin/sh
# -*- mode: sh -*-

# Definir las variables CHARP_* en bash_profile.
export PGDATABASE="$CHARP_PGDATABASE"
export PGHOST="$CHARP_PGHOST"
export PGPORT="$CHARP_PGPORT"
export PGUSER="$CHARP_PGUSER"

# Definir CHARPDIR en bash_profile.
if [ ! -d "$CHARPDIR" ]; then
    echo La variable CHARPDIR no está definida. >&2
    exit 1
fi

BASEDIR="$CHARPDIR"
TESTDIR="$BASEDIR/scripts/test"

# La ubicación del ->SQL generado por Architect
SQL_EXPORT="$HOME/Documents/charp.sql"
