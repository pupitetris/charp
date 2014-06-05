-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.


-- CHARP data types.

-- Allows charp_function_params to automatically detect when a Remote Procedure requests the user's ID
CREATE DOMAIN charp_user_id AS integer;

CREATE TYPE charp_param_type AS ENUM (
	'UID', -- Will be replaced by the ID of the user in request.pl so the client can't fake it.
	'INT',
	'STR',
	'BOOL',
	'DATE',
	'INTARR',
	'STRARR',
	'BOOLARR'
);

CREATE TYPE charp_error_code AS ENUM (
	'USERUNK',
	'PROCUNK',
	'REQUNK',
	'REPFAIL',
	'ASSERT',
	'USERPARMPERM',
	'USERPERM',
	'MAILFAIL',
	'DATADUP',
	'NOTFOUND',
	'EXIT'
);

CREATE TYPE charp_account_status AS ENUM (
	'ACTIVE',
	'DISABLED',
	'DELETED'
);


-- CHARP functions.


CREATE OR REPLACE FUNCTION charp_log_error(_code character varying, _username character varying, _ip_addr INET, _res character varying, _msg character varying, _params character varying[])
  RETURNS void AS
$BODY$
BEGIN
	INSERT INTO error_log VALUES(DEFAULT, CURRENT_TIMESTAMP, _code::charp_error_code, _username, _ip_addr, _res, _msg, _params);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION charp_raise(_code text, VARIADIC _args text[] DEFAULT ARRAY[]::text[])
  RETURNS void AS
$BODY$
DECLARE
	_i integer;
	_sqlcode text;
	_code_t charp_error_code;
BEGIN
	IF substring(_code FROM 1 FOR 1) = '-' THEN
	   _code_t := substring(_code FROM 2);
	ELSE
	   _code_t := _code;
	END IF;

	IF array_length(_args, 1) IS NOT NULL THEN
	   FOR _i IN 1 .. array_length(_args, 1) LOOP
	       _args[_i] := quote_literal(_args[_i]);
	   END LOOP;
	END IF;

	SELECT INTO _sqlcode
	       CASE _code
	       	    WHEN 'USERUNK'      THEN 'CH001'
	       	    WHEN 'PROCUNK'      THEN 'CH002'
	       	    WHEN 'REQUNK'       THEN 'CH003'
		    WHEN 'REPFAIL'      THEN 'CH004'
	       	    WHEN 'ASSERT'       THEN 'CH005'
	       	    WHEN 'USERPARMPERM' THEN 'CH006'
	       	    WHEN 'USERPERM'     THEN 'CH007'
	       	    WHEN 'MAILFAIL'     THEN 'CH008'
	       	    WHEN 'DATADUP'      THEN 'CH009'
	       	    WHEN 'NOTFOUND'     THEN 'CH010'
	       	    WHEN 'EXIT'         THEN 'CH011'
		    ELSE 'CH000'
	       END;

	RAISE EXCEPTION '|>%|{%}|', _code, array_to_string(_args, ',') USING ERRCODE = _sqlcode;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION charp_raise(text, VARIADIC text[]) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_raise(text, VARIADIC text[]) IS 'Levanta una excepción y manda un reporte a la tabla de error_log.';


CREATE OR REPLACE FUNCTION charp_account_get_id_by_username_status(_username character varying, _status charp_account_status)
  RETURNS integer AS
$BODY$
DECLARE
	_id integer;
BEGIN
	SELECT a.persona_id INTO _id FROM account AS a
	       WHERE a.username = _username AND a.status = _status;
	IF _id IS NULL THEN
	   PERFORM charp_raise('USERUNK', _username::text, _status::text);
	END IF;
	RETURN _id;
END
$BODY$
  LANGUAGE plpgsql STABLE;
ALTER FUNCTION charp_account_get_id_by_username_status(character varying, charp_account_status) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_account_get_id_by_username_status(character varying, charp_account_status) IS 'Obtiene el ID de una cuenta por username. Levanta una excepción si el username no existe.';


CREATE OR REPLACE FUNCTION charp_rp_get_function_by_name(_function_name character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	_name character varying;
BEGIN
	SELECT proname INTO _name FROM pg_proc WHERE proname = 'rp_' || _function_name;
	IF NOT FOUND THEN
	   PERFORM charp_raise('PROCUNK', _function_name);
	END IF;
	RETURN _name;
END
$BODY$
  LANGUAGE plpgsql STABLE;
ALTER FUNCTION charp_rp_get_function_by_name(character varying) OWNER TO M4_DEFN(user);


CREATE OR REPLACE FUNCTION charp_request_create(_username character varying, _ip_addr inet, _function_name character varying, _params character varying)
  RETURNS character varying AS
$BODY$
DECLARE
	_random_bytes character varying;
BEGIN
	_random_bytes := encode(gen_random_bytes(32), 'hex');
	INSERT INTO request VALUES(
		_random_bytes, 
		charp_account_get_id_by_username_status(_username, 'ACTIVE'),
		CURRENT_TIMESTAMP,
		_ip_addr,
		charp_rp_get_function_by_name(_function_name),
		_params
	);
	RETURN _random_bytes;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION charp_request_create(character varying, inet, character varying, character varying) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_request_create(character varying, inet, character varying, character varying) IS 'Registra una petición y devuelve un desafío para ser contestado por el cliente.';


CREATE OR REPLACE FUNCTION charp_get_function_params(_proargtypes oidvector)
  RETURNS charp_param_type ARRAY AS
$BODY$
DECLARE
	_fparams charp_param_type ARRAY;
BEGIN
	SELECT ARRAY( 
	       	      SELECT 
		      	     CASE format_type (_proargtypes[s.i], NULL)
			     	  WHEN 'charp_user_id'	     THEN 'UID'
				  WHEN 'integer'	     THEN 'INT'
				  WHEN 'character varying'   THEN 'STR'
				  WHEN 'text'		     THEN 'STR'
				  WHEN 'boolean'	     THEN 'BOOL'
				  WHEN 'date'		     THEN 'DATE'
				  WHEN 'integer[]'	     THEN 'INTARR'
				  WHEN 'character varying[]' THEN 'STRARR'
				  WHEN 'text[]'		     THEN 'STRARR'
				  WHEN 'boolean[]'	     THEN 'BOOLARR'
				  ELSE 'STR'
			     END
	        	     FROM generate_series(0, array_upper(_proargtypes, 1)) AS s(i)
		      ) 
	       INTO _fparams;
	RETURN _fparams;
END
$BODY$
  LANGUAGE plpgsql IMMUTABLE;
ALTER FUNCTION charp_get_function_params(_proargtypes oidvector) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_get_function_params(_proargtypes oidvector) IS 'Convierte el arreglo de parámetros que requiere una función de oids a charp_param_type.';


CREATE OR REPLACE FUNCTION charp_function_params(_function_name character varying)
  RETURNS charp_param_type ARRAY AS
$BODY$
DECLARE
	_fparams charp_param_type ARRAY;
BEGIN
	SELECT charp_get_function_params (p.proargtypes) INTO _fparams FROM pg_proc AS p WHERE p.proname = 'rp_' || _function_name;
	IF NOT FOUND THEN
	   PERFORM charp_raise('PROCUNK', _function_name);
	END IF;
	RETURN _fparams;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION charp_function_params(character varying) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_function_params(character varying) IS 'Devuelve los tipos de parámetros de entrada que requiere un store procedure de la base.';


CREATE OR REPLACE FUNCTION charp_request_check(_username character varying, _ip_addr inet, _chal character varying, _hash character varying)
  RETURNS TABLE(user_id integer, fname character varying, fparams charp_param_type ARRAY, req_params character varying) AS
$BODY$
DECLARE
	_req RECORD;
	_our_hash character varying;
BEGIN
	SELECT 
	       a.persona_id AS user_id, 
	       substring(p.proname FROM 4) AS fname, 
	       charp_get_function_params (p.proargtypes) AS fparams, 
	       r.params AS req_params, 
	       a.passwd 
	       INTO _req
	       FROM request AS r NATURAL JOIN account AS a NATURAL JOIN pg_proc AS p
	       WHERE a.username = _username AND
		     r.request_id = _chal AND 
		     r.ip_addr = _ip_addr;

	IF _req IS NULL THEN
		PERFORM charp_raise('REQUNK', _username, _ip_addr::text, _chal);
	END IF;

	DELETE FROM request WHERE request_id = _chal;

	_our_hash := encode(digest(_username || _chal || _req.passwd, 'sha256'), 'hex');
	IF _our_hash <> _hash THEN
		PERFORM charp_raise('REPFAIL', _username, _ip_addr::text, _chal);
	END IF;

	user_id := _req.user_id;
	fname := _req.fname;
	fparams := _req.fparams;
	req_params := _req.req_params;
	RETURN NEXT;
END
$BODY$
  LANGUAGE plpgsql VOLATILE;
ALTER FUNCTION charp_request_check(character varying, inet, character varying, character varying) OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION charp_request_check(character varying, inet, character varying, character varying) IS 'Checa que haya una petición registrada con los datos aportados y compara la firma(hash) con una computada por el server, y devuelve datos necesarios para hacer la ejecución.';


CREATE OR REPLACE FUNCTION rp_user_auth()
  RETURNS boolean AS
$BODY$
	SELECT TRUE;
$BODY$
  LANGUAGE sql IMMUTABLE;
ALTER FUNCTION rp_user_auth() OWNER TO M4_DEFN(user);
COMMENT ON FUNCTION rp_user_auth() IS 'Devuelve trivialmente TRUE, ya que si el usuario se autentificó, es que los pasos anteriores ocurrieron sin problema y las credenciales son auténticas.';