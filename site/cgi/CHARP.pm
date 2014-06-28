# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

package CHARP;

use DBI qw(:sql_types);

use Encode qw(encode decode);
use CGI::Fast qw(:cgi);
use JSON::XS;
use utf8;

require "CHARP-config.pm";
require "CHARP-strings-$CHARP_LANG.pm";
require "CHARP-$DB_DRIVER.pm";

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
    'DBI:CONNECT'	 => { 'code' => 	1, 'sev' => $ERROR_SEV_RETRY },
    'DBI:PREPARE'	 => { 'code' => 	2, 'sev' => $ERROR_SEV_INTERNAL },
    'DBI:EXECUTE'	 => { 'code' => 	3, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:REQPARM'	 => { 'code' => 	4, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:NOTPOST'	 => { 'code' => 	7, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:PATHUNK'	 => { 'code' => 	8, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:BADPARAM'	 => { 'code' =>	       11, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:NUMPARAM'	 => { 'code' =>	       12, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:BINDPARAM'	 => { 'code' =>	       16, 'sev' => $ERROR_SEV_INTERNAL },
    'CGI:FILESEND'	 => { 'code' =>	       19, 'sev' => $ERROR_SEV_INTERNAL },
    'SQL:USERUNK'	 => { 'code' => 	5, 'sev' => $ERROR_SEV_USER },
    'SQL:PROCUNK'	 => { 'code' => 	6, 'sev' => $ERROR_SEV_INTERNAL },
    'SQL:REQUNK'	 => { 'code' => 	9, 'sev' => $ERROR_SEV_INTERNAL },
    'SQL:REPFAIL'	 => { 'code' =>        10, 'sev' => $ERROR_SEV_USER },
    'SQL:ASSERT'	 => { 'code' =>	       13, 'sev' => $ERROR_SEV_INTERNAL },
    'SQL:USERPARAMPERM'	 => { 'code' =>	       14, 'sev' => $ERROR_SEV_PERM },
    'SQL:USERPERM'	 => { 'code' =>	       15, 'sev' => $ERROR_SEV_PERM },
    'SQL:MAILFAIL'	 => { 'code' =>	       17, 'sev' => $ERROR_SEV_USER },
    'SQL:DATADUP'	 => { 'code' =>        20, 'sev' => $ERROR_SEV_USER },
    'SQL:NOTFOUND'	 => { 'code' =>        21, 'sev' => $ERROR_SEV_USER },
    'SQL:EXIT'		 => { 'code' =>        18, 'sev' => $ERROR_SEV_EXIT }
);

foreach my $key (keys %ERRORS) {
    my $lvl = (split (':', $key))[0];
    my $err = $ERRORS{$key};
    $err->{'desc'} = $ERROR_DESCS{$key};
    $err->{'level'} = $ERROR_LEVELS{$lvl};
    $err->{'key'} = $key;
}

sub init {
    my $dbh = shift;

    my $err_sth = $dbh->prepare ('SELECT charp_log_error (?, ?, ?, ?, ?, ?)', prepare_attrs ());
    if (!defined $err_sth) {
	dispatch_error ({ 'err' => 'DBI:PREPARE', 'msg' => $DBI::errstr });
	return;
    }

    $err_sth->bind_param (1, undef, SQL_VARCHAR); # type
    $err_sth->bind_param (2, undef, SQL_VARCHAR); # login
    $err_sth->bind_param (3, undef, inet_type ()); # ip_addr
    $err_sth->bind_param (4, undef, SQL_VARCHAR); # resource
    $err_sth->bind_param (5, undef, SQL_VARCHAR); # msg
    $err_sth->bind_param (6, undef, params_type ()); # params

    my $chal_sth = $dbh->prepare ('SELECT charp_request_create (?, ?, ?, ?) AS chal', prepare_attrs ());
    if (!defined $chal_sth) {
	dispatch_error ({ 'err' => 'DBI:PREPARE', 'msg' => $DBI::errstr });
	return;
    }

    $chal_sth->bind_param (1, undef, SQL_VARCHAR); # login
    $chal_sth->bind_param (2, undef, inet_type ()); # ip_addr
    $chal_sth->bind_param (3, undef, SQL_VARCHAR); # resource
    $chal_sth->bind_param (4, undef, SQL_VARCHAR); # params

    my $chk_sth = $dbh->prepare ('SELECT * FROM charp_request_check (?, ?, ?, ?)', prepare_attrs ());
    if (!defined $chk_sth) {
	dispatch_error ({ 'err' => 'DBI:PREPARE', 'msg' => $DBI::errstr });
	return;
    }

    $chk_sth->bind_param (1, undef, SQL_VARCHAR); # login
    $chk_sth->bind_param (2, undef, inet_type ()); # ip_addr
    $chk_sth->bind_param (3, undef, SQL_VARCHAR); # chal
    $chk_sth->bind_param (4, undef, SQL_VARCHAR); # hash

    my $func_sth = $dbh->prepare ('SELECT charp_function_params (?) AS fparams', prepare_attrs ());
    if (!defined $func_sth) {
	dispatch_error ({ 'err' => 'DBI:PREPARE', 'msg' => $DBI::errstr });
	return;
    }

    $func_sth->bind_param (1, undef, SQL_VARCHAR); # fname

    my $ctx = { 
	'dbh'	   => $dbh, 
	'chal_sth' => $chal_sth,
	'chk_sth'  => $chk_sth,
	'func_sth' => $func_sth,
	'err_sth'  => $err_sth
    };

    $CHARP::ctx = $ctx;
    return $ctx;
}

# For testing, add ->pretty.
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
    my $state = $ctx->{'state'};
    my $statestr = $ctx->{'statestr'};
    my $objs = $ctx->{'objs'};

    $parms = undef if defined $parms && scalar (@$parms) < 0;

    my %err = %{$ERRORS{$err_key}};
    if (defined $parms) {
	$err{'desc'} = sprintf ($err{'desc'}, @$parms);
    }
    if (defined $msg) {
	$err{'msg'} = $msg;
    }
    if (defined $state) {
	$err{'state'} = $state;
    }
    $err{'statestr'} = (defined $statestr)? $statestr: $err_key;

    if (ref $objs eq 'ARRAY' && scalar (@$objs) > 0) {
	$err{'objs'} = $objs;
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
    my ($fcgi, $sth, $login, $ip_addr, $res) = @_;

    my ($dolog, $err_type, $code, $msg, @parms, $parms_str, $objs);
    my @fields = split ('\|', $sth->errstr, 3);
    if (substr ($fields[1], 0, 1) eq '>') { # Probablemente una excepción levantada por nosotros (charp_raise).
	if (substr ($fields[1], 1, 1) eq '-') {
	    $err_type = substr ($fields[1], 2);
	} else {
	    $dolog = 1;
	    $err_type = substr ($fields[1], 1);
	}
	$fields[2] =~ /^({('.*[^\\]\')})\|/;
	$parms_str = $1;

	$parms_str = "''" if $parms_str eq '';
	@parms = parse_csv (substr ($parms_str, 1, -1));
	$code = 'SQL:' . $err_type;
	$msg = substr ($fields[2], length ($parms_str) + 2);
	$objs = [$msg =~ /'([^']+)'/g];
    } else { # Error en el execute, no es una excepción nuestra.
	$err_type = 'EXECUTE';
	$code = 'DBI:' . $err_type;
	$msg = $sth->errstr;
	$parms_str = '';

	$msg =~ /^([^\n]+)/;
	my $errstr = $1;
	$objs = [$errstr =~ /"([^"]+)"/g];
    }

    if ($dolog) {
	$CHARP::ctx->{'err_sth'}->execute ($err_type, $login, $ip_addr, $res, $msg, $parms_str);
    }

    error_send ($fcgi, { 'err' => $code, 
			 'msg' => $msg, 
			 'parms' => \@parms, 
			 'state' => state_num ($sth, $dbh), 
			 'statestr' => state_str ($sth, $dbh),
			 'objs' => $objs 
		});
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
    connect_attrs_add ($attr_hash);

    my $dbh = DBI->connect_cached ("dbi:$DB_DRIVER:database=$DB_NAME;host=$DB_HOST;port=$DB_PORT" . dsn_add (), $DB_USER, $DB_PASS, $attr_hash);
    if (!defined $dbh) {
	dispatch_error ({'err' => 'DBI:CONNECT', 'msg' => $DBI::errstr });
    } else {
	$dbh->do ("SET application_name='fcgi'");
    }

    return $dbh;
}
