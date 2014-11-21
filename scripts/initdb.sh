#!/bin/bash

# This file is part of the CHARP project.
#
# Copyright © 2011 - 2014
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Database initializator

# Set the value of this variable to the name of the variable that points
# to the project's code base.
BASEDIR_VAR=CHARP_DIR

# Set the locale you want the script to run under (comment for system default).
export LANG="en_US.utf8"
export LC_ALL="en_US.utf8"

# *** No further editing needed after this line. ***

DB=
TESTDATA=
NOCAT=
DRY_RUN=

function showhelp {
	echo "Usage: $1 { -h | [-dry] [-x] [-db <dbname>] [-td] [-nocat] }

-h		Print this help text and exit.
-dry		Don't execute commands, print instead.
-x		Print all shell commands being executed (set -x).
-db <dbname>	Define database on which to operate.
-td		Feed test data to the database.
-nocat		Don't upload catalogs."
}

while [ ! -z "$1" ]; do
	case $1 in
		-h) # Print help.
			showhelp "$0"
			exit
			;;
		-dry) # Don't execute commands, print instead.
			DRY_RUN=1
			;;
		-x) # For debugging.
			set -x
			;;
		-db) # Define database on which to operate.
			if [ -z "$2" ]; then
				echo "Missing argument for -db." >&2
				exit 2;
			fi
			DB=$2
			shift 
			;;
		-td) # Feed test data to the database.
			TESTDATA=1 
			;;
		-nocat) # if -nocat, don't upload catalogs.
			NOCAT=1
			;;
		*)
			echo "Unrecognized option $1." >&2
			echo >&2
			showhelp "$0" >&2
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
    if [ ! -f "$SQL_EXPORT" ]; then
	echo "Warning: Exported SQL file $SQL_EXPORT not found" >&2
    else
	$BASEDIR/scripts/fix-sql.pl < "$SQL_EXPORT" > 04-tables.sql
    fi
fi

db_initialize

# Finally run all of the SQL files.

# -su runs the sql script as the database superuser (DBSUPERUSER).
# -d connects to the system schema (postgres, mysql...)
db_filter_or_exit 01-database.sql -su -d
db_filter_or_exit 02-charp.sql
db_filter_or_exit 03-types.sql
db_filter_or_exit 04-tables.sql
[ -e 04-tables-constraints.sql ] && db_filter_or_exit 04-tables-constraints.sql
db_filter_or_exit 05-functions.sql -su
[ -e 06-catalogs.sql -a -z "$NOCAT" ] && db_filter_or_exit 06-catalogs.sql -su
[ -e 07-views.sql ] && db_filter_or_exit 07-views.sql
[ -e 09-data.sql ] && db_filter_or_exit 09-data.sql -su
[ -e 98-testdata.sql -a ! -z "$TESTDATA" ] && db_filter_or_exit 98-testdata.sql -su
[ -e 99-test.sql -a ! -z "$TESTDATA" ] && db_filter_or_exit 99-test.sql -su
