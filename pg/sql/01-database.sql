-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

-- For user creation.

-- Extract user's password.
\set passwd '''' `[ -e $HOME/.pgpass ] && grep $PGUSER $HOME/.pgpass | cut -f5- -d:` ''''
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
       LC_COLLATE = 'M4_DEFN(locale)'
       LC_CTYPE = 'M4_DEFN(locale)'
       CONNECTION LIMIT = -1;

-- Connect to the newly created database for further configuration.
\c M4_DEFN(dbname)

-- This may be required.
--CREATE LANGUAGE plpythonu;
