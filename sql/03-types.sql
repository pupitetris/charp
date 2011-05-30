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
