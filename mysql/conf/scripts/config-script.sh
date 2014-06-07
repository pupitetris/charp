# Sourced by conf/config.sh

m4 -P "$DB_CONFIGDIR"/scripts/my-gen.cnf.m4 \
	-D CONF_DATABASE="$CONF_DATABASE" \
	-D CONF_HOST="$CONF_HOST" \
	-D CONF_PORT="$CONF_PORT" \
	-D CONF_USER="$CONF_USER" > "$DB_CONFIGDIR"/scripts/my-gen.cnf

m4 -P "$DB_CONFIGDIR"/scripts/my-gen.cnf.m4 \
	-D CONF_DATABASE="$CONF_DATABASE" \
	-D CONF_HOST="$CONF_HOST" \
	-D CONF_PORT="$CONF_PORT" \
	-D CONF_USER="$DB_SUPERUSER" > "$DB_CONFIGDIR"/scripts/my-su-gen.cnf

function check_cnf_mod {
	local file=$1

	if $(stat -c %a "$file") != 600; then
		echo File $file must have permissions 600. >&2
		echo chmod 600 \'$file\' >&2
		exit 4
	fi
}

check_cnf_mod "$DB_CONFIGDIR"/my.cnf
check_cnf_mod "$DB_CONFIGDIR"/my-su.cnf

# function called from db_filter that calls the database client silently.
# This obscure function runs psql with our own set of configuration variables
# and filters out unwanted psql NOTICEs.
function db_client {
	local sql_file=$1
	shift

	local cnf=my.cnf
	if [ "$1" = "-su" ]; then
		shift
		cnf=my-su.cnf
	fi

	local dbopts=
	if [ "$1" = "-d" ]; then
		shift
		dbopts="mysql"
	fi

	mysql --defaults-extra-file="$DB_CONFIGDIR"/$cnf $dbopts "$@" < "$sql_file"
}

function db_initialize {
	# Check if we can initialize the database before proceeding with the
	# rest of the SQL scripts so they don't fail.
	mysql --defaults-extra-file="$DB_CONFIGDIR"/my-su.cnf --database=mysql -e "DROP DATABASE IF EXISTS $CONF_DATABASE"
	
	if mysql --defaults-extra-file="$DB_CONFIGDIR"/my.cnf --vertical -e \
		"SELECT Id, User, Host, Command, Time, State, substr(info, 1, 100) AS Info FROM information_schema.processlist WHERE db = 'mysql';" 2>/dev/null; then
		echo 'The database couldn''t be deleted, a client is still connected.' >&2
		exit 2
	fi
}
