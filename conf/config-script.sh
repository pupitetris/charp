# Sourced by conf/config.sh

CONF_DATABASE=${PREFIX}_PGDATABASE
CONF_HOST=${PREFIX}_PGHOST
CONF_PORT=${PREFIX}_PGPORT
CONF_USER=${PREFIX}_PGUSER
CONF_DIR=${PREFIX}DIR

export PGDATABASE=${!CONF_DATABASE}
export PGHOST=${!CONF_HOST}
export PGPORT=${!CONF_PORT}
export PGUSER=${!CONF_USER}

# Define <PREFIX>DIR in your bash_profile.
if [ ! -d "${!CONF_DIR}" ]; then
    echo Variable $CONF_DIR is not defined. >&2
    exit 1
fi

BASEDIR="${!CONF_DIR}"
CONFIGDIR="$BASEDIR"/conf
TESTDIR="$BASEDIR"/scripts/test

# Directory where the project's SQL is found.
SQLDIR="$BASEDIR/sql"

# Under Cygwin, transform the directory to Windows notation, 
# since that's what the Windows-native Postgres requires for COPYs.
if [ $(uname -o) = 'Cygwin' ]; then
    IS_CYGWIN=1
    SQLDIR=$(sed 's#/cygdrive/\(\w\+\)/#\1:/#' <<< "$SQLDIR")
    DB_LOCALE=$DB_LOCALE_WIN
fi

# This obscure function runs psql with our own set of configuration variables
# and filters out unwanted psql NOTICEs.
function psql_filter {
    {
	local sql_file=$1
	echo $sql_file;
	shift
	m4 -P "$CONFIGDIR"/config_init.m4 \
	    -D CONF_USER=${!CONF_USER} \
	    -D CONF_DATABASE=${!CONF_DATABASE} \
	    -D CONF_LOCALE="$DB_LOCALE" \
	    -D CONF_SQLDIR="$SQLDIR" \
	    "$CONFIGDIR"/config.m4 "$CONFIGDIR"/config_end.m4 "$sql_file" > ${sql_file}-tmp
	psql -q -f ${sql_file}-tmp "$@" 2>&1 >&3 3>&- | grep -v ''\
'NOTICE:  \(function\|funci.n\) [^)]\+) \(does not exist, skipping\|no existe\)\|'\
'NOTICE:  CREATE TABLE / PRIMARY KEY \(will create implicit index\|crear. el .ndice impl.cito\)\|'\
'NOTICE:  \(constraint\|no existe la restricci.n\)\|'\
'NOTICE:  \(view\|la vista\)' >&2 3>&-
	rm -f ${sql_file}-tmp
    } 3>&1
}
