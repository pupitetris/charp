# Sintaxis: DEFINE(varname, valor)

# No debe ir ningún espacio entre DEFINE y el paréntesis o causará error.
# varname puede contener cualquier caracter, excepto coma y «.
# Espacios entre el paréntesis y varname serán ignorados.
# Espacios entre varname y la coma formarán parte de varname.
# Espacios entre la coma y el valor serán ignorados.
# El valor puede contener espacios, \n y cualquier caractér, menos coma, « y ).
# Espacios entre el valor y el paréntesis formarán parte del valor.
# varname y valor pueden ser rodeados por « y » para escapar #, espacios ignorados, coma y paréntesis.
# Puede usarse M4_DEFN(varname) dentro de valores para expandir el valor de un varname antes definido.

# Estas variables son adquiridas através de psql_filter, no se recomienda alterarlas:
DEFINE(user,	CONF_USER)
DEFINE(dbname,	CONF_DATABASE)
DEFINE(locale,	CONF_LOCALE)
DEFINE(collate,	CONF_COLLATE)
DEFINE(sqldir,	CONF_SQLDIR)
# Uncomment for MySQL:
#DEFINE(client,	localhost)
#DEFINE(myuser,	'CONF_USER'@'M4_DEFN(client)')
#DEFINE(passwd,	CONF_USER_PASSWD)
# CHARP data types for MySQL:
#DEFINE(charp_param_type, «ENUM('UID','INT','STR','BOOL','DATE','INTARR','STRARR','BOOLARR')»)
#DEFINE(charp_error_code, «ENUM('USERUNK','PROCUNK','REQUNK','REPFAIL','ASSERT','USERPARMPERM','USERPERM','MAILFAIL','DATADUP','NOTFOUND','EXIT')»)
#DEFINE(charp_account_status, «ENUM('ACTIVE','DISABLED','DELETED')»)
