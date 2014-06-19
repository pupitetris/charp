m4_define( «M4_CATALOG»,
«
\echo '$1'
DELETE FROM $1;
COPY $1 FROM 'M4_DEFN(sqldir)/catalogs/$1.csv' WITH (FORMAT csv, HEADER TRUE, DELIMITER '|', QUOTE '"')»)

m4_define(«M4_PROCEDURE_PROTO», «m4_patsubst(«$1», « \(DEFAULT\|default\) [^,)]+», «»)»)

# M4_PROCEDURE («prototype», «return type», function type {IMMUTABLE|STABLE|VOLATILE}, owner, 'comment', «body»)
m4_define( «M4_PROCEDURE»,
«DROP FUNCTION IF EXISTS M4_PROCEDURE_PROTO(«$1»);
CREATE FUNCTION $1
  RETURNS $2 AS
$BODY$
$6
$BODY$
  LANGUAGE plpgsql $3;
ALTER FUNCTION M4_PROCEDURE_PROTO(«$1») OWNER TO $4;
COMMENT ON FUNCTION M4_PROCEDURE_PROTO(«$1») IS $5»)

# M4_SQL_PROCEDURE («prototype», «return type», function type {IMMUTABLE|STABLE|VOLATILE}, owner, 'comment', «body»)
m4_define( «M4_SQL_PROCEDURE»,
«DROP FUNCTION IF EXISTS M4_PROCEDURE_PROTO(«$1»);
CREATE FUNCTION $1
  RETURNS $2 AS
$BODY$
$6
$BODY$
  LANGUAGE sql $3;
ALTER FUNCTION M4_PROCEDURE_PROTO(«$1») OWNER TO $4;
COMMENT ON FUNCTION M4_PROCEDURE_PROTO(«$1») IS $5»)

# An alias for M4_PROCEDURE (all procedures are actually functions in postgres).
# The idea is functions return "scalar" values. Procedures either void or tables.
m4_define( «M4_FUNCTION», «M4_PROCEDURE($@)») 
m4_define( «M4_SQL_FUNCTION», «M4_SQL_PROCEDURE($@)»)
