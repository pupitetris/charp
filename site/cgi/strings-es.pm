package CHARP;

use utf8;

%ERROR_DESCS = (
    'DBI:CONNECT'	=> 'No fue posible contactar a la base de datos.',
    'DBI:PREPARE'	=> 'Una sentencia SQL falló al ser preparada.',
    'DBI:EXECUTE'	=> 'La sentencia SQL no pudo ser ejecutada.',
    'CGI:REQPARM'	=> 'Faltan parámetros en petición HTTP.',
    'CGI:NOTPOST'	=> 'Método HTTP no es POST.',
    'CGI:PATHUNK'	=> 'Dirección HTTP no reconocida.',
    'CGI:BADPARAM'	=> '%s: Parámetros malformados `%s`.',
    'CGI:NUMPARAM'	=> '%s: %s parámetros requeridos, se entregaron %s.',
    'CGI:BINDPARAM'	=> '%s: No se pudo asociar el parámetro %s (`%s`) de `%s`.',
    'CGI:FILESEND'	=> 'Error al enviar archivo.',
    'SQL:USERUNK'	=> 'Usuario `%s` con status `%s` no encontrado.',
    'SQL:PROCUNK'	=> 'Función `%s` no encontrada.',
    'SQL:REQUNK'	=> 'Petición no encontrada.',
    'SQL:REPFAIL'	=> 'Firma errónea. Verifique nombre de usuario y contraseña.',
    'SQL:ASSERT'	=> 'Parámetros erróneos (`%s`).',
    'SQL:USERPARAMPERM'	=> 'El usuario %s no tiene permiso de realizar esta operación.',
    'SQL:USERPERM'	=> 'Su cuenta no tiene los permisos necesarios para realizar esta operación.',
    'SQL:MAILFAIL'	=> 'Hubo un error al intentar enviar un mensaje de correo a <%s>. Por favor, revise que la dirección esté bien escrita.',
    'SQL:DATADUP'	=> 'Los datos no pudieron ser insertados por duplicidad.',
    'SQL:NOTFOUND'	=> 'Información no encontrada.',
    'SQL:EXIT'		=> '%s'
);

%STRS = (
    'CGI:FILESEND:MISSING:MSG' => '%s: Parámetro `filename` faltante.',
    'CGI:FILESEND:OPENFAIL:MSG' => '%s: Error al abrir `%s` (%s).',
);    

1;
