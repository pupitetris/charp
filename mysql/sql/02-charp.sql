-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.


-- CHARP functions.


M4_PROCEDURE( charp_log_error, «_code varchar(255), _username varchar(20), _ip_addr int(11), _res varchar(255), _msg text, _params text», 
	      MODIFIES SQL DATA, M4_DEFN(myuser), 'Send an error report to the error log.', «
BEGIN 
    INSERT INTO error_log VALUES(DEFAULT, CURRENT_TIMESTAMP, _code, _username, _ip_addr, _res, _msg, _params);
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
