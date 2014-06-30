# Sourced by conf/config.sh

CONF_DATABASE=$(prefix DB_DATABASE)
[ -z "$CONF_DATABASE" ] && CONF_DATABASE=$DB_DATABASE
# If there was a command-line override (-db), use it.
[ ! -z "$DB" ] && CONF_DATABASE=$DB

CONF_HOST=$(prefix DB_HOST)
[ -z "$CONF_HOST" ] && CONF_HOST=$DB_HOST

CONF_PORT=$(prefix DB_PORT)
[ -z "$CONF_PORT" ] && CONF_PORT=$DB_PORT

CONF_USER=$(prefix DB_USER)
[ -z "$CONF_USER" ] && CONF_USER=$DB_USER

BASEDIR=$CONF_DIR
CONFIGDIR=$BASEDIR/conf
DB_CONFIGDIR=$BASEDIR/$DB_TYPE/conf
TESTDIR=$BASEDIR/scripts/test

OUR_RAND=$RANDOM

if [ $(uname -o) = 'Cygwin' ]; then
    IS_CYGWIN=1
fi

# Directory where the project's SQL is found.
SQLDIR=$BASEDIR/$DB_TYPE/sql

if [ $DB_OS = "win" ]; then
	# Transform the sql directory to Windows notation, 
	# since that's what the Windows-native Postgres requires for COPYs.
	WIN_SQLDIR=$(cygpath -aw "$SQLDIR")
fi

source "$DB_CONFIGDIR"/scripts/config-script.sh

sqlvars_end=$CONFIGDIR/scripts/sqlvars_end.m4
if [ ! -e "$sqlvars_end" ]; then
	echo 'm4_changecom(«--», «
»)
m4_divert«»m4_dnl
m4_undefine(' > "$sqlvars_end"
	echo -n m4_dumpdef | m4 -P 2>&1 | grep -v '^\(m4_defn\|m4_dnl\|m4_patsubst\):' | sed 's/^\([^:]\+\).*/		«\1»,/g' >> $sqlvars_end
	echo '		«CONF_USER»,
		«CONF_DATABASE»,
		«CONF_LOCALE»,
		«CONF_COLLATE»,
		«CONF_SQLDIR»,
		«CONF_USER_PASSWD»,
		«DEFINE»)«»m4_dnl' >> "$sqlvars_end"
fi

# Run the db client with our own set of configuration variables.
function db_filter {
	local sql_file=$1
	shift

	local sqldir=$SQLDIR
	if [ $DB_OS = "win" ]; then sqldir=$WIN_SQLDIR; fi

	local tmp=${sql_file}-$OUR_RAND-tmp
	local status=0

	(
		umask 0177
		m4 -P "$CONFIGDIR"/scripts/sqlvars_init.m4 \
			"$DB_CONFIGDIR"/scripts/sqlvars_init.m4 \
			-D CONF_USER="$CONF_USER" \
			-D CONF_USER_PASSWD="$CONF_USER_PASSWD" \
			-D CONF_DATABASE="$CONF_DATABASE" \
			-D CONF_LOCALE="$DB_LOCALE" \
			-D CONF_COLLATE="$DB_COLLATE" \
			-D CONF_SQLDIR="$sqldir" \
			"$CONFIGDIR"/sqlvars.m4 "$CONFIGDIR"/scripts/sqlvars_end.m4 "$sql_file" > "$tmp"
	) || status=4

	if [ $status = 0 ]; then
	    if [ -z "$DRY_RUN" ]; then
		echo $sql_file
		db_client "$tmp" "$@" || status=4
	    else
		echo '-- >>>' $sql_file '<<<'
		local width=$(($(wc -l < "$tmp" | wc -c) - 1))
		nl -ba -w $width -s : "$tmp"
		echo
	    fi
	fi

	rm -f "$tmp"
	return $status
}

function db_filter_or_exit {
    db_filter "$@" || exit $?
}
