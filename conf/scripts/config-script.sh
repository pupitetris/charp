# Sourced by conf/config.sh

CONF_DATABASE=$(prefix DB_DATABASE)
[ -z "$CONF_DATABASE" ] && CONF_DATABASE=$DB_DATABASE
# If there was a command-line override (-db), use it.
[ ! -z "$arg_DB" ] && export CONF_DATABASE=$arg_DB

CONF_HOST=$(prefix DB_HOST)
[ -z "$CONF_HOST" ] && CONF_HOST=$DB_HOST

CONF_PORT=$(prefix DB_PORT)
[ -z "$CONF_PORT" ] && CONF_PORT=$DB_PORT

CONF_USER=$(prefix DB_USER)
[ -z "$CONF_USER" ] && CONF_USER=$DB_USER

DB_CONFIGDIR=$BASEDIR/$DB_TYPE/conf

BASEDIR=$CONF_DIR
CONFIGDIR=$BASEDIR/conf
TESTDIR=$BASEDIR/scripts/test

if [ $(uname -o) = 'Cygwin' ]; then
    IS_CYGWIN=1
fi

# Directory where the project's SQL is found.
SQLDIR=$BASEDIR/$DB_TYPE/sql

if [ $DB_OS = "win" ]; then
	# Transform the sql directory to Windows notation, 
	# since that's what the Windows-native Postgres requires for COPYs.
	WIN_SQLDIR=$(sed 's#/cygdrive/\(\w\+\)/#\1:/#' <<< "$SQLDIR")
fi

source "$DB_CONFIGDIR"/scripts/config-script.sh

sqlvars_end=$CONFIGDIR/scripts/sqlvars_end.m4
if [ ! -e "$sqlvars_end" ]; then
	echo 'm4_changecom(«--», «
»)
m4_divert«»m4_dnl
m4_undefine(' > "$sqlvars_end"
	echo -n m4_dumpdef | m4 -P 2>&1 | grep -v '^\(m4_defn\|m4_dnl\):' | sed 's/^\([^:]\+\).*/		«\1»,/g' >> $sqlvars_end
	echo '		«CONF_USER»,
		«CONF_DATABASE»,
		«CONF_LOCALE»,
		«CONF_SQLDIR»,
		«DEFINE»)«»m4_dnl' >> "$sqlvars_end"
fi

# This obscure function runs the db client with our own set of configuration variables
# and filters out unwanted output.
function db_filter {
	local sql_file=$1
	echo $sql_file
	shift

	local sqldir=$SQLDIR
	if [ $DB_OS = "win" ]; then sqldir=$WIN_SQLDIR; fi

	local tmp=${sql_file}-$RANDOM-tmp

	m4 -P "$CONFIGDIR"/scripts/sqlvars_init.m4 \
		"$DB_CONFIGDIR"/scripts/sqlvars_init.m4 \
	    -D CONF_USER="$CONF_USER" \
	    -D CONF_DATABASE="$CONF_DATABASE" \
	    -D CONF_LOCALE="$DB_LOCALE" \
	    -D CONF_SQLDIR="$sqldir" \
	    "$CONFIGDIR"/sqlvars.m4 "$CONFIGDIR"/scripts/sqlvars_end.m4 "$sql_file" > "$tmp"
	db_client "$tmp" "$@"
#	rm -f "$tmp"
}
