#!/usr/bin/perl
#
# This file is part of the CHARP project.
#
# Copyright © 2011 - 2014
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

use CHARP;

sub request_challenge {
    my $fcgi = shift;
    my $ctx = shift;

    if ($fcgi->request_method () ne 'POST') {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:NOTPOST' });
	return;
    }

    my $req_anon = $fcgi->param ('anon');
    my $req_login = $fcgi->param ('login');
    my $req_res = $fcgi->param ('res');
    my $req_params = $fcgi->param ('params');

    if (defined $req_anon) {
	$req_login = '!anonymous';
    } 

    my $ip_addr = $fcgi->remote_addr ();

    if ($req_login eq '!anonymous') {
	$req_res = 'anon_' . $req_res;

	my $func_sth = $ctx->{'func_sth'};
	my $rv = $func_sth->execute ($req_res);
	if (!defined $rv) {
	    CHARP::error_execute_send ($fcgi, $func_sth, $req_login, $ip_addr, $req_res);
	    return;
	}
	my $rh = ${$func_sth->fetchall_arrayref ({})}[0];

	return request_reply_do ($fcgi, $ctx, $req_login, 
				 {'fname' => $req_res, 'fparams' => $rh->{'fparams'}, 'req_params' => $req_params});
    }

    if (!defined $req_res || !defined $req_params || !defined $req_login) {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:REQPARAM' });
	return;
    }
    
    my $chal_sth = $ctx->{'chal_sth'};
    my $rv = $chal_sth->execute ($req_login, $ip_addr, $req_res, $req_params);

    if (!defined $rv) {
	CHARP::error_execute_send ($fcgi, $chal_sth, $req_login, $ip_addr, $req_res);
	return;
    }

    my $res = ${$chal_sth->fetchall_arrayref ({})}[0];

    CHARP::json_send ($fcgi, $res);

    return;
}

%SQL_TYPES = (
    'UID' => SQL_INTEGER,
    'INT' => SQL_INTEGER,
    'STR' => SQL_VARCHAR,
    'BOOL' => SQL_BOOLEAN,
    'DATE' => SQL_DATE,
    'INTARR'  => CHARP::intarr_type,
    'STRARR'  => CHARP::strarr_type,
    'BOOLARR' => CHARP::boolarr_type
);

sub request_reply_file {
    my $fcgi = shift;
    my $fname = shift; # function name
    my $sth = shift;
    my $fd;

    my $res = $sth->fetchrow_hashref (NAME_lc);
    $sth->fetchrow_hashref (NAME_lc); # Avoid 'still Active' warning, exhaust response buffer.

    if (! exists $res->{'filename'}) {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:FILESEND', 'msg' => sprintf ($CHARP::STRS{'CGI:FILESEND:MISSING:MSG'}, $fname) });
	return;
    }
    if (! exists $res->{'mimetype'}) {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:FILESEND', 'msg' => sprintf ($CHARP::STRS{'CGI:FILESEND:MISSING:MSG'}, $fname) });
	return;
    }

    my %headers = (-type => $res->{'mimetype'});

    if (-e $res->{'filename'}) {
	if (! sysopen ($fd, $res->{'filename'}, 0)) {
	    CHARP::error_send ($fcgi, { 'err' => 'CGI:FILESEND', 'msg' => sprintf ($CHARP::STRS{'CGI:FILESEND:OPENFAIL:MSG'}, $fname, $res->{'filename'}, $!) });
	    return;
	}

	my @stat = stat ($fd);
	$headers{'-Content_Length'} = $stat[7];
	print $fcgi->header (%headers);

	my $buf;
	while (sysread ($fd, $buf, 4000)) {
	    print $buf;
	}

	close ($fd);
    } else {
	if (! open ($fd, $res->{'filename'})) {
	    CHARP::error_send ($fcgi, { 'err' => 'CGI:FILESEND', 'msg' => sprintf ($CHARP::STRS{'CGI:FILESEND:OPENFAIL:MSG'}, $fname, $res->{'filename'}, $!) });
	    return;
	}
	
	print $fcgi->header (%headers);

	# Slurp!
	my $tmp = $/;
	undef $/;
	print <$fd>;
	$/ = $tmp;
	
	close ($fd);
    }

    return;
}

sub request_reply {
    my $fcgi = shift;
    my $ctx = shift;

    my $req_login = $fcgi->param ('login');
    my $req_chal = $fcgi->param ('chal');
    my $req_hash = $fcgi->param ('hash');

    if (!defined $req_login || !defined $req_chal || !defined $req_hash) {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:REQPARAM' });
	return;
    }

    my $ip_addr = $fcgi->remote_addr ();
    my $chk_sth = $ctx->{'chk_sth'};
    my $rv = $chk_sth->execute ($req_login, $ip_addr, $req_chal, $req_hash);

    if (!defined $rv) {
	CHARP::error_execute_send ($fcgi, $chk_sth, $req_login, $ip_addr, 'REQUEST_CHECK');
	return;
    }

    my $req = ${$chk_sth->fetchall_arrayref ({})}[0];
    
    return request_reply_do ($fcgi, $ctx, $req_login, $req);
}

sub request_reply_do {
    my $fcgi = shift;
    my $ctx = shift;
    
    my $req_login = shift;
    my $req = shift;

    my $func_name = $req->{'fname'};
    my $func_params = $req->{'fparams'};
    my $req_params = $req->{'req_params'};
    my $req_user_id = $req->{'user_id'};

    my $ip_addr = $fcgi->remote_addr ();

    my @func_params_arr = split (',', substr ($func_params, 1, -1));
    my $num_fparams = scalar (@func_params_arr);

    my $req_params_arr = eval { CHARP::json_decode ($req_params); };
    if ($@ ne '') {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:BADPARAM', 'msg' => $@, 'parms' => [ $func_name, $req_params ]});
	return;
    }

    my $placeholders = '?,' x $num_fparams;
    chop $placeholders;

    $num_fparams-- if $func_params_arr[0] eq 'UID';
    if (scalar (@$req_params_arr) != $num_fparams) {
	CHARP::error_send ($fcgi, { 'err' => 'CGI:NUMPARAM', 'parms' => [ $func_name, scalar (@func_params_arr), scalar (@$req_params_arr) ]});
	return;
    }

    my $sth = $ctx->{'dbh'}->prepare_cached (CHARP::call_procedure_query ("rp_$func_name ($placeholders)"), CHARP::prepare_attrs ());
    if (!defined $sth) {
	CHARP::dispatch_error ({ 'err' => 'ERROR_DBI:PREPARE', 'msg' => $DBI::errstr });
	return;
    }

    my $i = 1;
    my $count = 0;
    foreach my $type (@func_params_arr) {
	my $val;
	if ($type eq 'UID') {
	    $val = $req_user_id;
	} else {
	    last if scalar (@$req_params_arr) == 0;
	    $val = shift (@$req_params_arr);
	    $val = undef if $val eq '';
	    if ($type eq 'BOOLARR' && ref $val eq 'ARRAY') {
		my @arr = map { ($_)? 1: 0 } @$val;
		$val = \@arr;
	    }
	    $count ++;
	}

	eval { $sth->bind_param ($i, $val, $TYPES{$type}); };
	if ($@ ne '') {
	    CHARP::error_send ($fcgi, { 'err' => 'CGI:BINDPARAM', 'msg' => $@, 'parms' => [ $func_name, $count, $val, $req_params ]});
	    return;
	}
	$i++;
    }

    my $info_error;
    $CHARP::INFO_HANDLER = sub {
	my $raise = shift;
	$info_error = CHARP::info_handler ($fcgi, $raise);
    };

    my $rv = $sth->execute ();

    $CHARP::INFO_HANDLER = undef;
    if ($info_error) {
	CHARP::error_send ($fcgi, $info_error);
	return;
    }
    
    if (!defined $rv) {
	CHARP::error_execute_send ($fcgi, $sth, $req_login, $ip_addr, $func_name);
	return;
    }

    if ($func_name =~ /^file_/ || $func_name =~ /^anon_file_/) {
	return request_reply_file ($fcgi, $func_name, $sth);
    }

    my @fields;
    my $names = $sth->{NAME_lc_hash};
    foreach my $name (keys %$names) {
	$fields[$names->{$name}] = $name;
    }

    CHARP::json_print_headers ($fcgi);

    print '{"fields":["' . 
	join ('","', @fields) .
	'"],"data":' .
	CHARP::json_encode ($sth->fetchall_arrayref ()) .
	'}';

    return;
}

sub request_main {
    my $fcgi = shift;
    my $ctx = shift;

    if ($fcgi->url('-absolute' => 1) eq '/request') {
	return request_challenge ($fcgi, $ctx);
    }

    if ($fcgi->url('-absolute' => 1) eq '/reply') {
	return request_reply ($fcgi, $ctx);
    }

    CHARP::error_send ($fcgi, { 'err' => 'CGI:PATHUNK' });
    return;
}

sub main {
    my $dbh = CHARP::connect ();
    return if !defined $dbh;

    my $ctx = CHARP::init ($dbh);

    # Loop mientras lleguen peticiones
    CHARP::dispatch (\&request_main, $ctx);
    $dbh->disconnect ();
}

main ();
