-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

-- Tipos de dato para CHARP.
CREATE DOMAIN charp_user_id AS integer;

CREATE TYPE charp_param_type AS ENUM (
	'UID', -- Será reemplazado por el id del usuario en request.pl.
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
	'EXIT'
);

CREATE TYPE charp_account_status AS ENUM (
	'ACTIVE',
	'DISABLED',
	'DELETED'
);
