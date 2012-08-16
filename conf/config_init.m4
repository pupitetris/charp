m4_divert(-1)
m4_changequote(`«', `»')
m4_define( «DEFINE»,
	   «m4_ifelse( «$#», 2,
	   	       «m4_define(««$»$1», «$2»)»,
		       «m4_errprint(m4___program__:m4___file__:m4___line__:«$0: 2 arguments required, got $#»)
		        m4_m4exit(1))»)»)

m4_define( «M4_CATALOG»,
«
\echo '$1'
DELETE FROM $1;
COPY $1 FROM 'M4_DEFN(sqldir)/catalogs/$1.csv' WITH (FORMAT csv, HEADER TRUE, DELIMITER '|', QUOTE '"')»)

# M4_FUNCTION («prototype», «return type», function type {STATIC|STABLE|VOLATILE}, owner, 'comment', «body»)
m4_define( «M4_FUNCTION»,
«\o /dev/null
DROP FUNCTION IF EXISTS $1;
\o
CREATE FUNCTION $1
  RETURNS $2 AS
$BODY$
$6
$BODY$
  LANGUAGE plpgsql $3;
ALTER FUNCTION $1 OWNER TO $4;
COMMENT ON FUNCTION $1 IS $5»)

m4_define( «M4_DEFN»,
	   «m4_defn(««$»$1»)»)
