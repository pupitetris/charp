-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

CREATE DATABASE M4_DEFN(dbname);

-- Connect to the newly created database for further configuration.
\u M4_DEFN(dbname)

M4_PROCEDURE(echo, msg text, DETERMINISTIC, M4_DEFN(myuser), 
			'Simple function that allows us to send messages to the user''s console',
			SELECT msg AS '');
	
