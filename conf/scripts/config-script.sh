# Sourced by conf/config.sh

if [ -z "${!${PREFIX}_DB_DATABASE}" ]; then
	CONF_DATABASE=DB_DATABASE
else
	CONF_DATABASE=${PREFIX}_DB_DATABASE
fi

if [ -z "${!${PREFIX}_DB_HOST}" ]; then
	CONF_DATABASE=DB_HOST
else
	CONF_DATABASE=${PREFIX}_DB_HOST
fi

if [ -z "${!${PREFIX}_DB_PORT}" ]; then
	CONF_DATABASE=DB_PORT
else
	CONF_DATABASE=${PREFIX}_DB_PORT
fi

if [ -z "${!${PREFIX}_DB_USER}" ]; then
	CONF_DATABASE=DB_USER
else
	CONF_DATABASE=${PREFIX}_DB_USER
fi

# Define <PREFIX>DIR in your bash_profile.
CONF_DIR=${PREFIX}DIR

if [ -z "${!CONF_DIR}" ]; then
    echo Variable $CONF_DIR is not defined. >&2
    exit 1
fi
if [ -d "${!CONF_DIR}" ]; then
    echo $CONF_DIR value ${!CONF_DIR} is not a directory. >&2
    exit 1
fi

BASEDIR="${!CONF_DIR}"
CONFIGDIR="$BASEDIR"/conf
TESTDIR="$BASEDIR"/scripts/test

if [ $(uname -o) = 'Cygwin' ]; then
    IS_CYGWIN=1
fi

# Directory where the project's SQL is found.
SQLDIR="$BASEDIR/$DB_TYPE/sql"

if [ $DB_OS = "win" ]; then
	# Transform the sql directory to Windows notation, 
	# since that's what the Windows-native Postgres requires for COPYs.
	WIN_SQLDIR=$(sed 's#/cygdrive/\(\w\+\)/#\1:/#' <<< "$SQLDIR")
fi

source $BASEDIR/$DB_TYPE/conf/scripts/config-script.sh

sqlvars_end=$CONFIGDIR/scripts/sqlvars_end.m4
if [ ! -e "$sqlvars_end" ]; then
	echo 'm4_changecom(«--», «
»)
m4_divert«»m4_dnl
m4_undefine(' > $sqlvars_end
	echo -n m4_dumpdef | m4 -P 2>&1 | grep -v '^\(m4_defn\|m4_dnl\):' | sed 's/^\([^:]\+\).*/		«\1»,/g' >> $sqlvars_end
	echo '		«CONF_USER»,
		«CONF_DATABASE»,
		«CONF_LOCALE»,
		«CONF_SQLDIR»,
		«DEFINE»)«»m4_dnl' >> $sqlvars_end
fi

# This obscure function runs the db client with our own set of configuration variables
# and filters out unwanted output.
function db_filter {
	local sql_file=$1
	echo $sql_file
	shift

	local sqldir=$SQLDIR
	if [ $DB_OS = "win" ]; then sqldir=$WIN_SQLDIR; fi

	m4 -P "$CONFIGDIR"/scripts/sqlvars_init.m4 \
	    -D CONF_USER=${!CONF_USER} \
	    -D CONF_DATABASE=${!CONF_DATABASE} \
	    -D CONF_LOCALE="$DB_LOCALE" \
	    -D CONF_SQLDIR="$sqldir" \
	    "$CONFIGDIR"/sqlvars.m4 "$CONFIGDIR"/scripts/sqlvars_end.m4 "$sql_file" > ${sql_file}-tmp
	db_client ${sql_file}-tmp "$@"
	rm -f ${sql_file}-tmp
}
