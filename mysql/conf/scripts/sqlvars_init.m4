m4_define( «M4_CATALOG»,
«
CALL echo ('$1');
DELETE FROM $1;
LOAD DATA INFILE 'M4_DEFN(sqldir)/catalogs/$1.csv' INTO TABLE $1
	 FIELDS TERMINATED BY '|' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
	 LINES TERMINATED BY '\n' STARTING BY '' IGNORE 1 LINES»)

# M4_PROCEDURE (name, «args», 
#               characteristics [[NOT] DETERMINISTIC] [CONTAINS SQL|NO SQL|READS SQL DATA|MODIFIES SQL DATA], 
#               definer user, 'comment', «body»)
m4_define( «M4_PROCEDURE»,
«
DROP PROCEDURE IF EXISTS $1;
\d //
CREATE DEFINER=$4 PROCEDURE $1 ($2)
	   COMMENT $5 $3
	   $6 //
\d ;
DO NULL»)

# M4_FUNCTION (name, «args», return type,
#              characteristics [[NOT] DETERMINISTIC] [CONTAINS SQL|NO SQL|READS SQL DATA|MODIFIES SQL DATA], 
#              definer user, 'comment', «body»)
m4_define( «M4_FUNCTION»,
«
DROP FUNCTION IF EXISTS $1;
\d //
CREATE DEFINER=$5 FUNCTION $1 ($2)
	   RETURNS $3
	   COMMENT $6 $4
	   $7 //
\d ;
DO NULL»)
