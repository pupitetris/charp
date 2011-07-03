-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

-- For user creation.

\set conf_user_q '''' :conf_user ''''
-- Extract user's password.
\set conf_passwd_q '''' `grep $PGUSER $HOME/.pgpass | cut -f5- -d:` ''''
-- Create user if it doesn't exist.
\set QUIET on
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
SELECT charp_create_user(:conf_user_q, :conf_passwd_q);
\o

DROP FUNCTION charp_create_user(_username text, _passwd text);
\set QUIET off

-- End of user creation.


CREATE DATABASE :conf_db
  WITH OWNER = :conf_user
       TEMPLATE = template0
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = :conf_locale_q
       LC_CTYPE = :conf_locale_q
       CONNECTION LIMIT = -1;

-- Connect to the newly created database for further configuration.
\c :conf_db

-- This may be required.
-- CREATE LANGUAGE plpythonu;
