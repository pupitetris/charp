#!/usr/bin/perl
# This file is part of the CHARP project.
#
# Copyright © 2011
#   Free Software Foundation Europe, e.V.,
#   Talstrasse 110, 40217 Dsseldorf, Germany
#
# Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

# Correcciones para usar tipos nativos de SQL y otras cosillas.
#1. Exportar sql en architect
#2. Guardar el sql en un archivo
#3. correr ./fix-sql.pl archivo > ../sql/04-tables.sql

use Encode qw (from_to);

use POSIX;

@uname = POSIX::uname ();
if ($uname[0] =~ /^CYGWIN/) {
    $is_cyg = 1;
} else {
    $is_cyg = 0;
}

@buff = ();
$n = 0;
%others = ();
%types = ();
for ($n = 0; $l = <>; $n++) {
    $l =~ s/\r//;
    if ($l =~ /^ +(\w+) OTHER/) {
	$others{$1} = $n;
    }
    if ($l =~ /^COMMENT ON COLUMN (\w+\.)*(\w+) IS 'TYPE (\w+(\(\d+\))?( ARRAY)?)/) {
	$key = $2;
	$type = $3;
	if (exists $others{$key}) {
	    $buff[$others{$key}] =~ s/$key OTHER/$key $type/;
	    if ($l =~ /\';$/) {
		$l = '';
	    } else {
		$l =~ s/IS \'TYPE.*\n/IS \'/;
	    }
	}
    }
    if ($l =~ /^COMMENT ON COLUMN (\w+\.)*(\w+) IS 'TYPE (\w+) AS ([^;]+)/) {
	$key = $2;
	$type = $3;
	$decl = $4;
	if (! exists $types{$type}) {
	    chop $decl; # trailing \'
	    $decl =~ s/''/'/g;
	    $types{$type} = "CREATE TYPE $type AS $decl;\n\n";
	}
	if (exists $others{$key}) {
	    $buff[$others{$key}] =~ s/$key OTHER/$key $type/;
	    $l = '';
	}
    }
    if ($is_cyg) { # Power Architect saves in latin1 on Windows.
	from_to ($l, 'iso-8859-1', 'utf8');
    }
    push @buff, $l;
}

foreach $type (sort keys %types) {
    unshift @buff, $types{$type};
}

print '-- This file is part of the CHARP project.
--
-- Copyright © 2011
--   Free Software Foundation Europe, e.V.,
--   Talstrasse 110, 40217 Dsseldorf, Germany
--
-- Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

';

print @buff;
