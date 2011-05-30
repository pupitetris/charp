# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

use DBI qw(:sql_types);
use DBD::Pg qw(:pg_types);

package CHARP;

use Encode qw(encode decode);
use CGI::Fast qw(:cgi);
use JSON::XS;
use utf8;

$DB_NAME = 'myproject';
$DB_HOST = 'localhost';
$DB_PORT = '5432';
$DB_USER = 'postgres';
$DB_PASS = 'tat1nha';
$DB_DRIVER = 'Pg';

%ERROR_LEVELS = (
    'DATA' => 1,
    'SQL'  => 2,
    'DBI'  => 3,
    'CGI'  => 4,
    'HTTP' => 5
);

$ERROR_SEV_INTERNAL = 1;
$ERROR_SEV_PERM = 2;
$ERROR_SEV_RETRY = 3;
$ERROR_SEV_USER = 4;
$ERROR_SEV_EXIT = 5;

%ERRORS = (
    'DBI:CONNECT'	 => { 'code' => 	1, 'sev' => $ERROR_SEV_RETRY,		'desc' => 'No fue posible contactar a la base de datos.' },
    'DBI:PREPARE'	 => { 'code' => 	2, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Una sentencia SQL falló al ser preparada.' },
    'DBI:EXECUTE'	 => { 'code' => 	3, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'La sentencia SQL no pudo ser ejecutada.' },
    'CGI:REQPARM'	 => { 'code' => 	4, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Faltan parámetros en petición HTTP.' },
    'CGI:NOTPOST'	 => { 'code' => 	7, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Método HTTP no es POST.' },
    'CGI:PATHUNK'	 => { 'code' => 	8, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Dirección HTTP no reconocida.' },
    'CGI:BADPARAM'	 => { 'code' =>	       11, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => '%s: Parámetros malformados `%s`.' },
    'CGI:NUMPARAM'	 => { 'code' =>	       12, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => '%s: %s parámetros requeridos, se entregaron %s.' },
    'CGI:BINDPARAM'	 => { 'code' =>	       16, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => '%s: No se pudo asociar el parámetro %s (`%s`) de `%s`.' },
    'CGI:FILESEND'	 => { 'code' =>	       19, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Error al enviar archivo.' },
    'SQL:USERUNK'	 => { 'code' => 	5, 'sev' => $ERROR_SEV_USER,		'desc' => 'Usuario `%s` con status `%s` no encontrado.' },
    'SQL:PROCUNK'	 => { 'code' => 	6, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Función `%s` no encontrada.' },
    'SQL:REQUNK'	 => { 'code' => 	9, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Petición no encontrada.' },
    'SQL:REPFAIL'	 => { 'code' =>        10, 'sev' => $ERROR_SEV_USER,		'desc' => 'Firma errónea. Verifique nombre de usuario y contraseña.' },
    'SQL:ASSERT'	 => { 'code' =>	       13, 'sev' => $ERROR_SEV_INTERNAL,	'desc' => 'Parámetros erróneos (`%s`).' },
    'SQL:USERPARAMPERM'	 => { 'code' =>	       14, 'sev' => $ERROR_SEV_PERM,		'desc' => 'El usuario %s no tiene permiso de realizar esta operación.' },
    'SQL:USERPERM'	 => { 'code' =>	       15, 'sev' => $ERROR_SEV_PERM,		'desc' => 'Su cuenta no tiene los permisos necesarios para realizar esta operación.' },
    'SQL:MAILFAIL'	 => { 'code' =>	       17, 'sev' => $ERROR_SEV_USER,		'desc' => 'Hubo un error al intentar enviar un mensaje de correo a <%s>. Por favor, revise que la dirección esté bien escrita.' },
    'SQL:DATADUP'	 => { 'code' =>        20, 'sev' => $ERROR_SEV_EXIT,		'desc' => 'Los datos no pudieron ser insertados por duplicidad.' },
    'SQL:EXIT'		 => { 'code' =>        18, 'sev' => $ERROR_SEV_EXIT,		'desc' => '%s' }
);

foreach my $key (keys %ERRORS) {
    my $lvl = (split (':', $key))[0];
    my $err = $ERRORS{$key};
    $err->{'level'} = $ERROR_LEVELS{$lvl};
    $err->{'key'} = $key;
}

# Para pruebas, agregar ->pretty.
$JSON = JSON::XS->new;

sub json_print_headers {
    my $fcgi = shift;

    print $fcgi->header (-type => 'application/json',
			 -expires => 'now',
			 -charset => 'UTF-8'
	);
}

sub json_encode {
    return encode ('UTF-8', $JSON->encode (shift));
}

sub json_decode {
    return $JSON->decode (shift);
}

sub json_send {
    my $fcgi = shift;
    my $struct = shift;

    json_print_headers ($fcgi);
    print json_encode ($struct);
}

sub error_send {
    my $fcgi = shift;
    my $ctx = shift;

    my $err_key = $ctx->{'err'};
    my $msg = $ctx->{'msg'};
    my $parms = $ctx->{'parms'};
    $parms = undef if defined $parms && scalar (@$parms) < 0;

    my %err = %{$ERRORS{$err_key}};
    if (defined $parms) {
	$err{'desc'} = sprintf ($err{'desc'}, @$parms);
    }
    if (defined $msg) {
	$err{'msg'} = $msg;
    }

    json_send ($fcgi, { 'error' => \%err });
    return;
}

sub parse_csv {
    my $text = shift;
    my @new = ();

    while ($text =~ m{
    '([^\'\\]*(?:(?:\\.|'')[^\'\\]*)*)',?
      | ([^,]+),?
      | ,
    }gx) {
	my $l = $+;
	$l =~ s/''/'/g;
	push (@new, $l);
    }

    push (@new, undef) if substr ($text, -1,1) eq ',';
    return @new;
}

sub error_execute_send {
    my ($fcgi, $errstr, $err_sth, $login, $ip_addr, $res) = @_;

    my ($code, $msg, @parms);
    my @fields = split ('\|', $errstr, 3);
    if (substr ($fields[1], 0, 1) eq '>') { # Probablemente una excepción levantada por nosotros.
	my $err_type = substr ($fields[1], 1);
	$fields[2] =~ /^({('.*[^\\]\')})\|/;
	my $parms_str = $1;
	my $query = '';

	$parms_str = "''" if $parms_str eq '';
	@parms = parse_csv (substr ($parms_str, 1, -1));
	$code = 'SQL:' . $err_type;
	$msg = substr ($fields[2], length ($parms_str) + 2);

	$err_sth->execute ($err_type, $login, $ip_addr, $res, $msg, $parms_str);
    } else { # Error en el execute, no es una excepción nuestra.
	$code = 'DBI:EXECUTE';
	$msg = $errstr;
    }
    error_send ($fcgi, { 'err' => $code, 'msg' => $msg, 'parms' => \@parms });
}

sub dispatch_error {
    my $ctx = shift;
    dispatch (sub { error_send (@_); return 1; }, $ctx);
}

use Data::Dumper;

sub fcgi_bail {
    my $data = shift;
    my $inside_dispatch = shift;

    CGI::Fast->new if !$inside_dispatch;
    print "\n" . Dumper ($data) . "\n";
    exit;
}

sub dispatch {
    my $callback = shift;
    my $ctx = shift;

    while (my $fcgi = CGI::Fast->new) {
	my $res = &$callback ($fcgi, $ctx);
	last if defined $res;
    }
}

sub connect {
    my ($attr_hash) = @_;

    $attr_hash = {} if (!defined $attr_hash);
    $attr_hash->{'pg_enable_utf8'} = 1;

    my $dbh = DBI->connect_cached ("dbi:$DB_DRIVER:database=$DB_NAME;host=$DB_HOST;port=$DB_PORT", $DB_USER, $DB_PASS, $attr_hash);
    if (!defined $dbh) {
	dispatch_error ({'err' => 'DBI:CONNECT', 'msg' => $DBI::errstr });
    } else {
	$dbh->do ("SET application_name='fcgi'");
    }

    return $dbh;
}
