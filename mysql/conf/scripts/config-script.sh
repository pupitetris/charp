# Sourced by conf/config.sh

function process_cnf {
	local file=$1
	local user=$2

	m4 -P -D CONF_DATABASE="$CONF_DATABASE" \
		-D CONF_HOST="$CONF_HOST" \
		-D CONF_PORT="$CONF_PORT" \
		-D CONF_USER="$user" \
		"$DB_CONFIGDIR"/scripts/my-gen.cnf.m4 > "$file"
}

function check_cnf_mod {
	local file=$1

	if [ $(stat -c %a "$file") != 600 ]; then
		echo File $file must have permissions 600. >&2
		echo chmod 600 \'$file\' >&2
		exit 4
	fi
}

process_cnf "$DB_CONFIGDIR"/scripts/my-gen.cnf "$CONF_USER"
process_cnf "$DB_CONFIGDIR"/scripts/my-su-gen.cnf "$DB_SUPERUSER"

check_cnf_mod "$DB_CONFIGDIR"/my.cnf
check_cnf_mod "$DB_CONFIGDIR"/my-su.cnf

function mymysql {
	local cnf=my.cnf
	if [ "$1" = "-su" ]; then
		shift
		cnf=my-su.cnf
	fi

	local dbopts=
	if [ "$1" = "-d" ]; then
		shift
		dbopts="--database=mysql"
	fi

	(
		cd $DB_CONFIGDIR
		mysql --defaults-extra-file=$cnf $dbopts "$@"
	)
}

# function called from db_filter that calls the database client silently.
# This obscure function runs psql with our own set of configuration variables
# and filters out unwanted psql NOTICEs.
function db_client {
	local sql_file=$1
	shift

	mymysql "$@" < "$sqlfile"
}

function db_initialize {
	# Check if we can initialize the database before proceeding with the
	# rest of the SQL scripts so they don't fail.
	mymysql -su -d -e "DROP DATABASE IF EXISTS $CONF_DATABASE"
	
	if mymysql --vertical -e \
		"SELECT Id, User, Host, Command, Time, State, substr(info, 1, 100) AS Info 
			FROM information_schema.processlist WHERE db = 'mysql';" 2>/dev/null; then
		echo 'The database couldn''t be deleted, a client is still connected.' >&2
		exit 2
	fi
}
