/* $PostgreSQL: pgsql/contrib/pgcrypto/pgcrypto.sql.in,v 1.15 2007/11/13 04:24:28 momjian Exp $ */

-- Adjust this setting to control where the objects get created.
SET search_path = public;

-- We only need these two functions. Extracted from POSTGRESDIR/share/contrib/pgcrypto.sql

CREATE OR REPLACE FUNCTION gen_random_bytes(int4)
RETURNS bytea
AS '$libdir/pgcrypto', 'pg_random_bytes'
LANGUAGE 'C' VOLATILE STRICT;

CREATE OR REPLACE FUNCTION digest(text, text)
RETURNS bytea
AS '$libdir/pgcrypto', 'pg_digest'
LANGUAGE C IMMUTABLE STRICT;
