# Sourced by conf/config.sh

export PGDATABASE=$CONF_DATABASE
export PGHOST=$CONF_HOST
export PGPORT=$CONF_PORT
export PGUSER=$CONF_USER

# function called from db_filter that calls the database client silently.
# This obscure function runs psql with our own set of configuration variables
# and filters out unwanted psql NOTICEs.
function db_client {
	local sql_file=$1
	shift

	local suopts=
	if [ "$1" = "-su" ]; then
		shift
		suopts="-U $DB_SUPERUSER"
	fi

	local dbopts=
	if [ "$1" = "-d" ]; then
		shift
		dbopts="-d postgres"
	fi

	PGOPTIONS=--client-min-messages=warning psql -q -f "$sql_file" $suopts $dbopts "$@"
}

function db_initialize {
	[ ! -z "$DRY_RUN" ] && return;

	# Check if we can initialize the database before proceeding with the
	# rest of the SQL scripts so they don't fail.
	PGOPTIONS=--client-min-messages=warning psql -q -d postgres -U $DB_SUPERUSER -c "DROP DATABASE IF EXISTS $CONF_DATABASE"
	
	if psql -q -U $DB_SUPERUSER -c "SELECT procpid, application_name, client_addr FROM pg_stat_activity WHERE current_query NOT LIKE '% pg_stat_activity %';" 2>/dev/null; then
		echo 'The database couldn''t be deleted, a client is still connected.' >&2
		exit 2
	fi
}
