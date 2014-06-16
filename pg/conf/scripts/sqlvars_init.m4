m4_define( «M4_CATALOG»,
«
\echo '$1'
DELETE FROM $1;
COPY $1 FROM 'M4_DEFN(sqldir)/catalogs/$1.csv' WITH (FORMAT csv, HEADER TRUE, DELIMITER '|', QUOTE '"')»)

# M4_FUNCTION («prototype», «return type», function type {IMMUTABLE|STABLE|VOLATILE}, owner, 'comment', «body»)
m4_define( «M4_FUNCTION»,
«DROP FUNCTION IF EXISTS $1;
CREATE FUNCTION $1
  RETURNS $2 AS
$BODY$
$6
$BODY$
  LANGUAGE plpgsql $3;
ALTER FUNCTION $1 OWNER TO $4;
COMMENT ON FUNCTION $1 IS $5)»)

# M4_SQL_FUNCTION («prototype», «return type», function type {IMMUTABLE|STABLE|VOLATILE}, owner, 'comment', «body»)
m4_define( «M4_SQL_FUNCTION»,
«DROP FUNCTION IF EXISTS $1;
CREATE FUNCTION $1
  RETURNS $2 AS
$BODY$
$6
$BODY$
  LANGUAGE sql $3;
ALTER FUNCTION $1 OWNER TO $4;
COMMENT ON FUNCTION $1 IS $5)»)
