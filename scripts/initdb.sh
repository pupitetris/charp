#!/bin/bash

# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Database initializator

# For debugging:
#set -x

# Set the value of this variable to the name of the variable that points
# to the project's code base.
BASEDIR_VAR=CHARP_DIR

# Set the locale you want the script to run under (comment for system default).
export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

# *** No further editing needed after this line. ***

arg_DB=
TESTDATA=
NOCAT=

while [ ! -z "$1" ]; do
	case $1 in
		-db) 
			if [ -z "$2" ]; then
				echo "Missing argument for -db." >&2
				exit 2;
			fi
			arg_DB=$2
			shift 
			;;
		-td) 
			TESTDATA=1 
			;;
		-nocat)
			# if -nocat, don't upload catalogs.
			NOCAT=1
			;;
		*)
			echo "Unrecognized option $1." >&2
			exit 2;
			;;
	esac
	shift
done

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

cd $SQLDIR

# Under Cygwin, make sure permissions are right and kill
# any cgi-fcgi scripts so the database can be dropped.
if [ ! -z "$IS_CYGWIN" ]; then
    chmod -f 644 catalogs/*.csv
    chmod -f 644 datos_prueba/*.csv

    $BASEDIR/scripts/kill-fcgi.sh
fi

# SQL outputs of PowerArchitect or MySQL Workbench.
if [ ! -z "$SQL_EXPORT" ]; then
    $BASEDIR/scripts/fix-sql.pl < "$SQL_EXPORT" > 04-tables.sql
fi

db_initialize

# Finally run all of the SQL files.

# -su runs the sql script as the database superuser (DBSUPERUSER).
# -d connects to the system schema (postgres, mysql...)
db_filter 01-database.sql -su -d
db_filter 02-charp.sql
db_filter 03-types.sql
db_filter 04-tables.sql
[ -e 04-tables-constraints.sql ] && db_filter 04-tables-constraints.sql
db_filter 05-functions.sql -su
[ -e 06-catalogs.sql ] && [ -z "$NOCAT" ] && db_filter 06-catalogs.sql -su
[ -e 07-views.sql ] && db_filter 07-views.sql
[ -e 09-data.sql ] && db_filter 09-data.sql -su
[ -e 98-testdata.sql ] && [ ! -z "$TESTDATA" ] && db_filter 98-testdata.sql -su
[ -e 99-test.sql ] && [ ! -z "$TESTDATA" ] && db_filter 99-test.sql -su
