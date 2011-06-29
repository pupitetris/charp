#!/bin/bash
# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Comandos para inicializar la BD

BASEDIR=$CHARPDIR

export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

if [ "$1" = "-db" ]; then
    DB=$2
    shift 2
fi

if [ "$1" = "-td" ]; then
    TESTDATA=1
    shift
fi

if [ "$1" = "-nocat" ]; then
    NOCAT=1
    shift
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

# Directorio donde se encuentra el SQL (para catálogos).
if [ $(uname -o) = 'Cygwin' ]; then
    # En cygwin, transformar a notación Windows, ya que Postgres es instalado como programa nativo.
    DIR=$(sed 's#/cygdrive/\(\w\+\)/#\1:/#' <<< "$BASEDIR/sql")
    IS_CYGWIN=1

    chmod -f 644 "$BASEDIR/sql/catalogs/"*.csv
    chmod -f 644 "$BASEDIR/sql/datos_prueba/"*.csv
else
    DIR="$BASEDIR/sql"
fi

cd $DIR

if [ -e "$SQL_EXPORT" ]; then
    $BASEDIR/scripts/fix-sql.pl < "$SQL_EXPORT" > $BASEDIR/sql/04-tables.sql
fi

[ -z "$IS_CYGWIN" ] || $BASEDIR/scripts/kill-fcgi.sh

# Checamos si podemos inicializar la base de datos antes de proceder con todos los scripts de 
# sql para que no fallen.

[ -z "$DB" ] || PGDATABASE=$DB

psql -d postgres -c "DROP DATABASE IF EXISTS $PGDATABASE"

if psql -c "SELECT procpid, application_name, client_addr FROM pg_stat_activity WHERE current_query NOT LIKE '% pg_stat_activity %';" 2>/dev/null; then
    echo 'No se pudo borrar la base de datos, algún cliente sigue conectado.' >&2
    exit 2
fi

if [ ! -z "$IS_CYGWIN" ]; then
    # El sistema de locale de Postgres es dependiente del SO: usar 'Spanish, Mexico' para Windows.
    add_cmd=';s/es_MX.utf8/Spanish, Mexico/g'
fi

sed "s/%db%/$PGDATABASE/g$add_cmd" 01-database.sql | psql -d postgres

psql -f 02-pgcrypto.sql
psql -f 03-types.sql
psql -f 04-tables.sql 2>&1 | grep -v 'NOTICE:  CREATE TABLE / PRIMARY KEY \(will create implicit index\|crear. el .ndice impl.cito\)'
#psql -f 04-tables-constraints.sql 2>&1 | grep -v 'NOTICE:  \(constraint\|no existe la restricci.n\)'
psql -f 05-functions.sql
#[ -z "$NOCAT" ] && sed 's#%dir%#'"$DIR"'#g' 06-catalogs.sql | psql
#psql -f 07-views.sql 2>&1 | grep -v 'NOTICE:  \(view\|la vista\)'
#psql -f 09-data.sql
#[ -z "$TESTDATA" ] || sed 's#%dir%#'"$DIR"'#g' 98-testdata.sql | psql
psql -f 99-test.sql
