#!/bin/bash

# Set the value of this variable to the prefix of your project.
PREFIX=CHARP

# pg for PostgreSQL, mysql for MySQL
DB_TYPE=pg

# Platform under which the DBMS is running. Valid values: win unix
DB_OS=win

# Location of the ->SQL export generated by Power Architect
# (Uncomment and set accordingly if you are using Power Architect)
#SQL_EXPORT="$HOME/Documents/charp.sql"

# You may want to set this to a locale suitable to your country.
# This is for Spanish/Mexico, UTF-8 (CHARP uses UTF-8 all around,
# it is not recommended to switch to a diferent encoding).
# For mysql, use utf_general_ci
DB_LOCALE=es_MX.utf8

if [ $DB_OS = "win" ]; then
	# Locales under Windows have a different nomeclature and Postgres
	# is system-dependent for locale specification. Uncomment and set 
	# this accordingly if you are using Postgres for Windows.
	DB_LOCALE="«Spanish, Mexico»"
fi

# Set this accordingly if you are using Cygwin and need to run
# the native executables instead of the ones from Cygwin.
# Otherwise, leave it commented.
#DB_BINDIR="/cygdrive/c/Program Files/PostgreSQL/9.3/bin/"
#DB_BINDIR="/cygdrive/c/Program Files/MySQL/MySQL Server 5.5/bin"

# This is usually correct:
# mysql: DBSUPERUSER=root
DB_SUPERUSER=postgres

# *** No further editing needed after this line. ***
CONF_DIR=${PREFIX}DIR
source ${!CONF_DIR}/conf/config-script.sh
