-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

M4_PROCEDURE(charp_create_user, «_username text, _passwd text», DETERMINISTIC MODIFIES SQL DATA, CURRENT_USER,
			'Create user if it doesn''t exist',
«_f: BEGIN 
	   DECLARE _found integer;
	   SELECT count(*) INTO _found FROM mysql.user WHERE user = _username;
	   IF _found > 0 THEN LEAVE _f; END IF;

	   set @s = concat('CREATE USER ''', _username, '''@''localhost'' IDENTIFIED BY ''', _passwd, '''');
	   PREPARE _charp_create_user_prep FROM @s;
	   EXECUTE _charp_create_user_prep;
	   DEALLOCATE PREPARE _charp_create_user_prep;
END»);

CALL charp_create_user('M4_DEFN(user)', 'M4_DEFN(passwd)');
DROP PROCEDURE charp_create_user;

CREATE DATABASE M4_DEFN(dbname)
	   CHARACTER SET = 'utf8'
	   COLLATE = 'M4_DEFN(collate)';

-- Connect to the newly created database for further configuration.
\u M4_DEFN(dbname)

M4_PROCEDURE(echo, _msg text, DETERMINISTIC, M4_DEFN(myuser), 
			'Simple function that allows us to send messages to the user''s console',
			SELECT _msg AS '');
	
