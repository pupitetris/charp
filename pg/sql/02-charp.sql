-- This file is part of the CHARP project.
--
-- Copyright © 2011 - 2014
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


M4_PROCEDURE( «charp_log_error(_code character varying, _username character varying, _ip_addr INET, _res character varying, _msg character varying, _params character varying[])»,
	      void, VOLATILE, M4_DEFN(user), 'Send an error report to the error log.', «
BEGIN 
	  INSERT INTO error_log VALUES(DEFAULT, CURRENT_TIMESTAMP, _code::charp_error_code, _username, _ip_addr, _res, _msg, _params);
END;»);


M4_PROCEDURE( «charp_raise(_code text, VARIADIC _args text[] DEFAULT ARRAY[]::text[])»,
	      void, VOLATILE, M4_DEFN(user), 'Raise and log an exception with the CHARP format for client consumption.', «
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
	       CASE _code_t
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
END;»);


M4_FUNCTION( «charp_account_get_id_by_username_status(_username character varying, _status charp_account_status)»,
	     integer, STABLE, M4_DEFN(user), «'Get the user id for a given user name, raise USERUNK if not found.'», «
DECLARE
	_id integer;
BEGIN
	SELECT a.persona_id INTO _id FROM account AS a
	       WHERE a.username = _username AND a.status = _status;
	IF _id IS NULL THEN
	   PERFORM charp_raise('USERUNK', _username::text, _status::text);
	END IF;
	RETURN _id;
END;»);


M4_FUNCTION( «charp_rp_get_function_by_name(_function_name character varying)»,
	     character varying, STABLE, M4_DEFN(user), «'Find given function with prefix rp_, raise PROCUNK if not found.'», «
DECLARE
	_name character varying;
BEGIN
	SELECT proname INTO _name FROM pg_proc WHERE proname = 'rp_' || _function_name;
	IF NOT FOUND THEN
	   PERFORM charp_raise('PROCUNK', _function_name);
	END IF;
	RETURN _name;
END;»);


M4_FUNCTION( «charp_request_create(_username character varying, _ip_addr inet, _function_name character varying, _params character varying)»,
	     character varying, VOLATILE, M4_DEFN(user), 'Registers a request returning a corresponding challlenge for the client to respond.', «
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
END;»);


M4_FUNCTION( «charp_get_function_params(_proargtypes oidvector)»,
	     charp_param_type ARRAY, IMMUTABLE, M4_DEFN(user), 'Convert the parameter array of a function for given oids to charp_param_type', «
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
END;»);


M4_FUNCTION( «charp_function_params(_function_name character varying)»,
	     charp_param_type ARRAY, VOLATILE, M4_DEFN(user), 'Return the input parameter types that a given stored procedure requires.', «
DECLARE
	_fparams charp_param_type ARRAY;
BEGIN
	SELECT charp_get_function_params (p.proargtypes) INTO _fparams FROM pg_proc AS p WHERE p.proname = 'rp_' || _function_name;
	IF NOT FOUND THEN
	   PERFORM charp_raise('PROCUNK', _function_name);
	END IF;
	RETURN _fparams;
END;»);


M4_PROCEDURE( «charp_request_check(_username character varying, _ip_addr inet, _chal character varying, _hash character varying)»,
	      «TABLE(user_id integer, fname character varying, fparams charp_param_type ARRAY, req_params character varying)», 
	      VOLATILE, M4_DEFN(user), 'Check that a given request is registered with the given data and compare the hash with one locally computed. Return the necessary data to execute.', «
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
END;»);


M4_PROCEDURE( «rp_check_url(_url character varying)», boolean, IMMUTABLE, M4_DEFN(user),
	      'Check that an entrypoint URL was created by the system.', «
DECLARE
	_hash_pos integer;
	_url_part text;
	_hash_part text;
	_our_hash text;
BEGIN
	_hash_pos := position ('#' IN _url);
	IF _hash_pos < 1 THEN
	   PERFORM charp_raise('ASSERT', 'URL has #');
	END IF;
	
	_url_part := substring (_url FROM 1 FOR _hash_pos - 1);
	_hash_part := substring (_url FROM _hash_pos + 1);
	_our_hash := rp_sign_url(_url_part);

	IF _our_hash = _hash_part THEN
	   RETURN TRUE;
	END IF;
	RETURN FALSE;
END;»);


-- url_check_hash1 and 2 are salts that need to be defined in sqlvars.m4.
-- For added security, you may want to create a remote procedure that returns a modified URL with a timestamp embedded.
M4_SQL_FUNCTION( «rp_sign_url(_url character varying)», character varying, IMMUTABLE, M4_DEFN(user),
	      	 'Generate a signature for a given URL.', «
		 SELECT encode(digest('M4_DEFN(url_check_hash1)' || _url || 'M4_DEFN(url_check_hash2)', 'sha256'), 'hex');»);


M4_SQL_FUNCTION( «rp_user_auth()», boolean, IMMUTABLE, M4_DEFN(user),
	         «'Trivially return TRUE. If the user was authenticated, everything went OK with challenge-request sequence and there is nothing left to do: success.'»,
	         «SELECT TRUE»);
