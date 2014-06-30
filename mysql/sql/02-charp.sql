-- This file is part of the CHARP project.
--
-- Copyright © 2011 - 2014
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.


-- CHARP functions.


M4_PROCEDURE( charp_log_error, «_code varchar(255), _username varchar(20), _ip_addr varchar(16), _res varchar(255), _msg text, _params text», 
	      MODIFIES SQL DATA, M4_DEFN(myuser), 'Send an error report to the error log.', «
BEGIN 
    INSERT INTO error_log VALUES(DEFAULT, CURRENT_TIMESTAMP, _code, _username, inet_aton(_ip_addr), _res, _msg, _params);
END;»);


M4_PROCEDURE( charp_raise_full, «_code text, _arg1 text, _arg2 text, _arg3 text, _arg4 text»,
	      NO SQL, M4_DEFN(myuser), 'Raise and log an exception with the CHARP format for client consumption.', «
BEGIN
    DECLARE _code_t M4_DEFN(charp_error_code);
    DECLARE _sqlcode text;
    DECLARE _msg text;

    IF substring(_code FROM 1 FOR 1) = '-' THEN
       SET _code_t := substring(_code FROM 2);
    ELSE 
       SET _code_t := _code;
    END IF;

    SET _msg := CONCAT( '|>', _code, '|{', 
    	     		CONCAT_WS( ',', 
				   IF(ISNULL(_arg1),NULL,QUOTE(_arg1)), 
				   IF(ISNULL(_arg2),NULL,QUOTE(_arg2)), 
				   IF(ISNULL(_arg3),NULL,QUOTE(_arg3)), 
				   IF(ISNULL(_arg4),NULL,QUOTE(_arg4))
				   ), 
			'}|');

    CASE _code_t
	 WHEN 'USERUNK'      THEN SIGNAL SQLSTATE 'CH001' SET MESSAGE_TEXT = _msg;
	 WHEN 'PROCUNK'      THEN SIGNAL SQLSTATE 'CH002' SET MESSAGE_TEXT = _msg;
	 WHEN 'REQUNK'       THEN SIGNAL SQLSTATE 'CH003' SET MESSAGE_TEXT = _msg;
	 WHEN 'REPFAIL'      THEN SIGNAL SQLSTATE 'CH004' SET MESSAGE_TEXT = _msg;
	 WHEN 'ASSERT'       THEN SIGNAL SQLSTATE 'CH005' SET MESSAGE_TEXT = _msg;
	 WHEN 'USERPARMPERM' THEN SIGNAL SQLSTATE 'CH006' SET MESSAGE_TEXT = _msg;
	 WHEN 'USERPERM'     THEN SIGNAL SQLSTATE 'CH007' SET MESSAGE_TEXT = _msg;
	 WHEN 'MAILFAIL'     THEN SIGNAL SQLSTATE 'CH008' SET MESSAGE_TEXT = _msg;
	 WHEN 'DATADUP'      THEN SIGNAL SQLSTATE 'CH009' SET MESSAGE_TEXT = _msg;
	 WHEN 'NOTFOUND'     THEN SIGNAL SQLSTATE 'CH010' SET MESSAGE_TEXT = _msg;
	 WHEN 'EXIT'	 THEN SIGNAL SQLSTATE 'CH011' SET MESSAGE_TEXT = _msg;
    ELSE 
	 SIGNAL SQLSTATE 'CH000' SET MESSAGE_TEXT = _msg;
    END CASE;
END;»);


-- Ugly repetition with these helper functions.
-- Thanks MySQL for no default parameter support and no variadic argument support after +10 years of requests.
M4_PROCEDURE( charp_raise4, «_code text, _arg1 text, _arg2 text, _arg3 text, _arg4 text»,
	      NO SQL, M4_DEFN(myuser), «'Raise and log an exception with the CHARP format for client consumption, 4 arguments.'», «
BEGIN
    CALL charp_raise_full(_code, _arg1, _arg2, _arg3, _arg4);
END;»);


M4_PROCEDURE( charp_raise3, «_code text, _arg1 text, _arg2 text, _arg3 text»,
	      NO SQL, M4_DEFN(myuser), «'Raise and log an exception with the CHARP format for client consumption, 3 arguments.'», «
BEGIN
    CALL charp_raise_full(_code, _arg1, _arg2, _arg3, NULL);
END;»);


M4_PROCEDURE( charp_raise2, «_code text, _arg1 text, _arg2 text»,
	      NO SQL, M4_DEFN(myuser), «'Raise and log an exception with the CHARP format for client consumption, 2 arguments.'», «
BEGIN
    CALL charp_raise_full(_code, _arg1, _arg2, NULL, NULL);
END;»);


M4_PROCEDURE( charp_raise1, «_code text, _arg1 text»,
	      NO SQL, M4_DEFN(myuser), «'Raise and log an exception with the CHARP format for client consumption, 1 argument.'», «
BEGIN
    CALL charp_raise_full(_code, _arg1, NULL, NULL, NULL);
END;»);


M4_PROCEDURE( charp_raise, «_code text»,
	      NO SQL, M4_DEFN(myuser), «'Raise and log an exception with the CHARP format for client consumption, no arguments.'», «
BEGIN
    CALL charp_raise_full(_code, NULL, NULL, NULL, NULL);
END;»);


M4_FUNCTION( charp_account_get_id_by_username_status, «_username varchar(20), _status M4_DEFN(charp_account_status)»,
	     integer, READS SQL DATA, M4_DEFN(myuser), «'Get the user id for a given user name, raise USERUNK if not found.'», «
BEGIN
	DECLARE	_id integer;

	SELECT a.persona_id INTO _id FROM account AS a
	       WHERE a.username = _username AND a.status = _status;
	IF _id IS NULL THEN
	   CALL charp_raise2('USERUNK', _username, _status);
	END IF;
	RETURN _id;
END;»);


M4_FUNCTION( charp_rp_get_function_by_name, _function_name varchar(60),
	     varchar(64), READS SQL DATA, M4_DEFN(myuser), «'Find given function with prefix rp_, raise PROCUNK if not found.'», «
BEGIN
	DECLARE	_name varchar(64);

	SELECT routine_name INTO _name FROM information_schema.routines 
	       WHERE routine_name = concat('rp_', _function_name) COLLATE utf8_general_ci;
	IF _name IS NULL THEN
	   CALL charp_raise1('PROCUNK', _function_name);
	END IF;
	RETURN _name;
END;»);


M4_FUNCTION( gen_random_bytes_hex, _count integer,
	     text, NOT DETERMINISTIC NO SQL, M4_DEFN(myuser), 'Return _count random bytes in hex representation.', «
BEGIN 
	DECLARE _str text;

	SET _str := '';
	SET _count := _count * 2;
	WHILE _count > 0 DO
	      SET _str := concat(_str, hex(rand() * 15));
	      SET _count := _count - 1;
	END WHILE;

	RETURN _str;
END;»);


M4_FUNCTION( charp_request_create, «_username varchar(20), _ip_addr varchar(16), _function_name varchar(60), _params text»,
	     text, NOT DETERMINISTIC MODIFIES SQL DATA, M4_DEFN(myuser), 'Registers a request returning a corresponding challlenge for the client to respond.', «
BEGIN
	DECLARE _random_bytes text;

	SET _random_bytes := gen_random_bytes_hex(32);
	INSERT INTO request VALUES(
		_random_bytes, 
		charp_account_get_id_by_username_status(_username, 'ACTIVE'),
		CURRENT_TIMESTAMP,
		inet_aton(_ip_addr),
		charp_rp_get_function_by_name(_function_name),
		_params
	);
	RETURN _random_bytes;
END;»);


M4_FUNCTION( charp_get_function_params, _function_name varchar(64),
	     text, READS SQL DATA, M4_DEFN(myuser), 'Return the input parameter types that a given stored procedure requires.', «
BEGIN
	DECLARE	_fparams text;

	SELECT group_concat(q.type SEPARATOR ',') INTO _fparams 
	       FROM (SELECT IF (parameter_name = '_uid', 'UID',
	       	    	        CASE data_type 
				     WHEN 'int'     THEN 'INT' 
			    	     WHEN 'varchar' THEN 'STR' 
				     WHEN 'text'    THEN 'STR'
				     WHEN 'boolean' THEN 'BOOL'
				     WHEN 'date'    THEN 'DATE'
				     ELSE 'STR'
			        END) AS type
			   FROM information_schema.parameters 
			   WHERE specific_name = _function_name COLLATE utf8_general_ci AND ordinal_position > 0 
			   ORDER BY ordinal_position
		    ) AS q;

	RETURN _fparams;
END;»);


M4_FUNCTION( charp_function_params, _function_name varchar(60),
	     text, READS SQL DATA, M4_DEFN(myuser), 'Return the input parameter types that a given stored procedure requires.', «
BEGIN
	DECLARE	_fparams text;

	SELECT charp_get_function_params (concat('rp_', _function_name)) INTO _fparams;
	IF _fparams IS NULL THEN
	   CALL charp_raise1('PROCUNK', _function_name);
	END IF;
	RETURN _fparams;
END;»);


M4_PROCEDURE( charp_request_check, «_username varchar(20), _ip_addr varchar(16), _chal text, _hash text»,
	      NOT DETERMINISTIC READS SQL DATA, M4_DEFN(myuser), 
	      'Check that a given request is registered with the given data and compare the hash with one locally computed. Return the necessary data to execute.', «
BEGIN
	DECLARE _our_hash text;
	DECLARE _user_id integer;
	DECLARE _fname varchar(60);
	DECLARE _fparams text;
	DECLARE _req_params text;
	DECLARE _passwd varchar(32);

	SELECT 
	       a.persona_id, 
	       substring(r.proname FROM 4), 
	       charp_get_function_params (r.proname), 
	       r.params, 
	       a.passwd
	       INTO _user_id, _fname, _fparams, _req_params, _passwd
	       FROM request AS r NATURAL JOIN account AS a JOIN information_schema.routines AS p ON p.routine_name = r.proname COLLATE utf8_general_ci
	       WHERE a.username = _username AND
		     r.request_id = _chal AND 
		     r.ip_addr = inet_aton(_ip_addr);

	IF _fname IS NULL THEN
	   CALL charp_raise3('REQUNK', _username, _ip_addr, _chal);
	END IF;

	DELETE FROM request WHERE request_id = _chal;

	SET _our_hash := sha2(concat(_username, _chal, _passwd), 256);
	IF _our_hash <> _hash THEN
	   CALL charp_raise3('REPFAIL', _username, _ip_addr, _chal);
	END IF;

	SELECT _user_id AS user_id, _fname AS fname, _fparams AS fparams, _req_params AS req_params;
END;»);


M4_PROCEDURE( rp_user_auth, «», DETERMINISTIC NO SQL, M4_DEFN(myuser),
	      «'Trivially return TRUE. If the user was authenticated, everything went OK with challenge-request sequence and there is nothing left to do: success.'»,
	      «SELECT TRUE»);
