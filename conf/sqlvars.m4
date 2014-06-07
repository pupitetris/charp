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
DEFINE(sqldir,	CONF_SQLDIR)
