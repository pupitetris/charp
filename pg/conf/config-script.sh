# Sourced by conf/config.sh

export PGDATABASE=${!CONF_DATABASE}
export PGHOST=${!CONF_HOST}
export PGPORT=${!CONF_PORT}
export PGUSER=${!CONF_USER}

# function called from db_filter that calls the database client silently.
# This obscure function runs psql with our own set of configuration variables
# and filters out unwanted psql NOTICEs.
function db_client {
    {
		local sql_file=$1
		shift
		psql -q -f ${sql_file} "$@" 2>&1 >&3 3>&- | grep -v ''\
'NOTICE:  \(function\|funci.n\) [^)]\+) \(does not exist, skipping\|no existe\)\|'\
'NOTICE:  CREATE TABLE / PRIMARY KEY \(will create implicit index\|crear. el .ndice impl.cito\)\|'\
'NOTICE:  \(constraint\|no existe la restricci.n\)\|'\
'NOTICE:  \(view\|la vista\)' >&2 3>&-
    } 3>&1
}

function db_initialize {
	if [ ! -z "$DB" ]; then
		export PGDATABASE=$DB
	fi
	
	# Check if we can initialize the database before proceeding with the
	# rest of the SQL scripts so they don't fail.
	psql -q -d postgres -U $DB_SUPERUSER -c "DROP DATABASE IF EXISTS $PGDATABASE"
	
	if psql -q -U $DB_SUPERUSER -c "SELECT procpid, application_name, client_addr FROM pg_stat_activity WHERE current_query NOT LIKE '% pg_stat_activity %';" 2>/dev/null; then
		echo 'The database couldn''t be deleted, a client is still connected.' >&2
		exit 2
	fi
}
