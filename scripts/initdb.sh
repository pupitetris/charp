#!/bin/bash
# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Commands to initialize the database

# Set the value of this variable to the name of the variable that points
# to the project's code base.
BASEDIR_VAR=CHARPDIR

# *** No further editing needed after this line. ***

BASEDIR=${!BASEDIR_VAR}

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
    echo "$BASEDIR_VAR is not defined." >&2
    exit 1
fi

if [ ! -d "$BASEDIR" ]; then
    echo "The value of \$$BASEDIR_VAR ($BASEDIR) does not point to a directory." >&2
    exit 3
fi

source "$BASEDIR/conf/config.sh"

cd $SQLDIR

# Under Cygwin, set the Windows-specific locale and make sure permissions are right
# and kill any cgi-fcgi scripts so the database can be dropped.
if [ ! -z "$IS_CYGWIN" ]; then
    chmod -f 644 catalogs/*.csv
    chmod -f 644 datos_prueba/*.csv

    $BASEDIR/scripts/kill-fcgi.sh
fi

if [ -e "$SQL_EXPORT" ]; then
    $BASEDIR/scripts/fix-sql.pl < "$SQL_EXPORT" > 04-tables.sql
fi

# Check if we can initialize the database before proceeding with the
# rest of the SQL scripts so they don't fail.

if [ ! -z "$DB" ]; then
    CONF_DATABASE=DB
    export PGDATABASE=$DB
fi

psql -d postgres -U $PGSUPERUSER -c "DROP DATABASE IF EXISTS $PGDATABASE"

if psql -U $PGSUPERUSER -c "SELECT procpid, application_name, client_addr FROM pg_stat_activity WHERE current_query NOT LIKE '% pg_stat_activity %';" 2>/dev/null; then
    echo 'The database couldn''t be deleted, a client is still connected.' >&2
    exit 2
fi

# Finally run all of the SQL files.
psql_filter -d postgres -U $PGSUPERUSER -f 01-database.sql
psql_filter -U $PGSUPERUSER -f 02-pgcrypto.sql
psql_filter -f 02-charp.sql
psql_filter -f 03-types.sql
psql_filter -f 04-tables.sql
[ -e 04-tables-constraints.sql ] && psql_filter -f 04-tables-constraints.sql
psql_filter -U $PGSUPERUSER -f 05-functions.sql
[ -e 06-catalogs.sql ] && [ -z "$NOCAT" ] && psql_filter -U $PGSUPERUSER -f 06-catalogs.sql
[ -e 07-views.sql ] && psql_filter -f 07-views.sql
[ -e 09-data.sql ] && psql_filter -U $PGSUPERUSER -f 09-data.sql
if [ -e 98-testdata.sql ]; then [ -z "$TESTDATA" ] || psql_filter -U $PGSUPERUSER -f 98-testdata.sql; fi
if [ -e 99-test.sql ]; then [ -z "$TESTDATA" ] || psql_filter -U $PGSUPERUSER -f 99-test.sql; fi
