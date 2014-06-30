-- This file is part of the CHARP project.
--
-- Copyright © 2011 - 2014
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

-- For user creation.

-- Create user if it doesn't exist.
CREATE FUNCTION charp_create_user(_username text, _passwd text)
  RETURNS VOID AS
$BODY$
BEGIN
    PERFORM 1 FROM pg_authid WHERE rolname = _username;
    IF FOUND THEN RETURN; END IF;

    EXECUTE $$
	CREATE ROLE $$ || _username || $$ WITH
		      LOGIN ENCRYPTED PASSWORD $$ || quote_literal(_passwd) || $$
		      NOSUPERUSER NOCREATEDB NOCREATEROLE;
    $$;
    UPDATE pg_authid SET rolcatupdate = FALSE WHERE rolname = _username;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;

-- Extract user's password.
\set passwd '''' `[ -e $HOME/.pgpass ] && grep $PGUSER $HOME/.pgpass | cut -f5- -d:` ''''

\o /dev/null
SELECT charp_create_user('M4_DEFN(user)', :passwd);
\o

DROP FUNCTION charp_create_user(_username text, _passwd text);

-- End of user creation.


CREATE DATABASE M4_DEFN(dbname)
  WITH OWNER = M4_DEFN(user)
       TEMPLATE = template0
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'M4_DEFN(collate)'
       LC_CTYPE = 'M4_DEFN(locale)'
       CONNECTION LIMIT = -1;

-- Connect to the newly created database for further configuration.
\c M4_DEFN(dbname)

-- pgcrypto stuff, needs superuser to install.

/* $PostgreSQL: pgsql/contrib/pgcrypto/pgcrypto.sql.in,v 1.15 2007/11/13 04:24:28 momjian Exp $ */

-- Adjust this setting to control where the objects get created.
--SET search_path = public;

-- We only need these two functions. Extracted from POSTGRESDIR/share/contrib/pgcrypto.sql

CREATE OR REPLACE FUNCTION gen_random_bytes(int4)
RETURNS bytea
AS '$libdir/pgcrypto', 'pg_random_bytes'
LANGUAGE C VOLATILE STRICT;

CREATE OR REPLACE FUNCTION digest(text, text)
RETURNS bytea
AS '$libdir/pgcrypto', 'pg_digest'
LANGUAGE C IMMUTABLE STRICT;

-- End of pgcrypto stuff

-- This may be required.
--CREATE LANGUAGE plpythonu;
