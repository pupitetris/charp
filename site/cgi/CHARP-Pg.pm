package CHARP;

use DBD::Pg qw(:pg_types);

%CHARP::pg_errcodes = ();
open (my $efd, 'Pg-errcodes.txt') || die "Can't open errcodes.txt file.";
while (my $l = <$efd>) {
    chomp $l;
    $l =~ s/^\s*//;
    next if $l =~ /^#/;
    next if $l =~ /^$/;
    next if $l =~ /^Section/;
    if ($l =~ /(^[0-9A-Z]{5})\s+([EWS])\s+(\w+)\s+(\w+)/) {
	$CHARP::pg_errcodes{$1} = $4;
    }
}

sub connect_attrs_add {
    my $attr_hash = shift;
    $attr_hash->{'pg_enable_utf8'} = 1;
    $attr_hash->{'pg_placeholder_nocolons'} = 1;
    $attr_hash->{'pg_prepare_now'} = 1;
}

sub dsn_add {
    return '';
}

sub prepare_attrs {
    return { 'pg_server_prepare' => 1 };
}

sub inet_type {
    return { 'pg_type' => PG_INET };
}

sub params_type {
    return { 'pg_type' => PG_VARCHARARRAY };
}

sub intarr_type {
    return { 'pg_type' => PG_INT4ARRAY };
}

sub strarr_type {
    return { 'pg_type' => PG_VARCHARARRAY };
}

sub boolarr_type {
    return { 'pg_type' => PG_BOOLARRAY };
}

sub state_num {
    my $sth = shift;
    my $dbh = shift;

    return $sth->state;
}

sub state_str {
    my $sth = shift;
    my $dbh = shift;

    return $CHARP::pg_errcodes{$sth->state};
}

sub call_procedure_query {
    my $proc = shift;
    return 'SELECT * FROM ' . $proc;
}

1;
