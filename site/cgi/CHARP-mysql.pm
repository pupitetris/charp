package CHARP;

sub connect_attrs_add {
    my $attr_hash = shift;
    $attr_hash->{'mysql_enable_utf8'} = 1;
}

sub dsn_add {
    my @attrs = (
	'mysql_server_prepare=1'
	);

    return ';' . join (';', @attrs);
}

sub prepare_attrs {
    return { };
}

sub inet_type {
    return SQL_VARCHAR;
}

sub params_type {
    return SQL_VARCHAR;
}

sub intarr_type {
    return SQL_VARCHAR;
}

sub strarr_type {
    return SQL_VARCHAR;
}

sub boolarr_type {
    return SQL_VARCHAR;
}

sub state_num {
    my $sth = shift;
    my $dbh = shift;

    return $dbh->{'mysql_errno'};
}

sub state_str {
    my $sth = shift;
    my $dbh = shift;

    return $dbh->{'mysql_error'};
}

1;
