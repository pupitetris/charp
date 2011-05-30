-- Este archivo necesita que se le reemplace %db% por el nombre de la base de datos.
CREATE DATABASE %db%
  WITH OWNER = postgres
       TEMPLATE = template0
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'es_MX.utf8'
       LC_CTYPE = 'es_MX.utf8'
       CONNECTION LIMIT = -1;

-- Conectarse a la base recién creada
 \c %db%

-- Esto puede ser requerido.
-- CREATE LANGUAGE plpythonu;
