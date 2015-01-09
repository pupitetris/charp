package CHARP;

use utf8;

use File::Path;
use File::Spec;
use File::Basename;
use File::Copy;

# Only way to catch INFO/NOTICES raised by stored procedures is through SIG{__WARN__}.
$INFO_HANDLER = undef;
sub warn_handler {
    my $msg = shift;
    if ($msg =~ /^INFO: +(\|>.*)/ && $INFO_HANDLER) {
	&$INFO_HANDLER (CHARP::raise_parse ($1));
	return;
    }
    warn $msg;
}

# Catch warnings to process INFO messages raised from stored procedures (for charp_cmd).
$SIG{'__WARN__'} = \&warn_handler;

sub cmderr {
    my $cmd = shift;
    my $msg = shift;
    $msg =~ s/$FILE_DIR/FILE_DIR/g;
    return { 'err' => 'CGI:CMDERR', 'msg' => "$cmd: $msg" };
}

# find a file relative to FILE_DIR, handle error conditions by returning an error hashref.
sub file_find {
    my $path = shift;
    my $cmd = shift;

    my ($fname, $dirname) = File::Basename::fileparse ($path);
    my $abs = File::Spec->canonpath (File::Spec->catdir ($FILE_DIR, $dirname));
    if (substr ($abs, 0, length ($FILE_DIR)) ne $FILE_DIR) {
	# Won't operate on paths that lead to files outside FILE_DIR
	return cmderr ($cmd, sprintf ($STRS{'CGI:CMDERR:BADPATH'}, $path));
    }

    return { 'dirname' => $abs, 'fname' => File::Spec->catfile ($abs, $fname) };
}

sub cmd_file_create {
    my ($cmd, $num_parms, $parms, $fcgi) = @_;

    if ($num_parms != 1) {
	return { 'err' => 'CGI:CMDNUMPARAM', 'parms' => [ $cmd, 1, $num_parms ] };
    }

    if ($fcgi->param ('file') eq undef) {
	return cmderr ($cmd, 'Missing file data.');
    }

    my $path = file_find ($parms->[0], $cmd);
    return $path if $path->{'err'};

    if (! -d $path->{'dirname'}) {
	eval { File::Path::make_path ($path->{'dirname'}, { mode => 0711 }) };
	if ($@ ne '') {
	    return cmderr ($cmd, 'make_path: ' . $@);
	}
    }

    my $fd;
    if (!open $fd, '>', $path->{'fname'}) {
	return cmderr ($cmd, 'open: ' . $path->{'fname'} . ' ' . $!);
    }

    # FIXME: if we enable uploads, we have to use different calls to deal with uploaded files.
    if (!$CGI::DISABLE_UPLOADS) {
	# http://perldoc.perl.org/CGI.html#PROCESSING-A-FILE-UPLOAD-FIELD
	die "TODO: code routine that handles file-based uploads.";
    }

    if (!print $fd (scalar $fcgi->param ('file'))) {
	return cmderr ($cmd, 'print: ' . $path->{'fname'} . ' ' . $!);
    }
    if (!close $fd) {
	return cmderr ($cmd, 'close: ' . $path->{'fname'} . ' ' . $!);
    }
    return undef;
}

sub cmd_file_delete {
    my ($cmd, $num_parms, $parms, $fcgi) = @_;

    if ($num_parms < 1 || $num_parms > 2) {
	return { 'err' => 'CGI:CMDNUMPARAM', 'parms' => [ $cmd, '1 or 2', $num_parms ] };
    }

    my $path = file_find ($parms->[0], $cmd);
    return $path if $path->{'err'};

    my $ignore_notfound = ($parms->[1])? 1: 0;
    if (! -f $path->{'fname'}) {
	return undef if $ignore_notfound;
	return cmderr ($cmd, sprintf ($STRS{'CGI:CMDERR:PATHNOTFOUND'}, $path));
    }
    
    if (unlink ($path->{'fname'})) {
	return undef;
    }
    return cmderr ($cmd, 'unlink: ' . $path->{'fname'} . ' ' . $!);
}

sub cmd_file_move {
    my ($cmd, $num_parms, $parms, $fcgi) = @_;

    if ($num_parms != 2) {
	return { 'err' => 'CGI:CMDNUMPARAM', 'parms' => [ $cmd, 2, $num_parms ] };
    }

    my $src = file_find ($parms->[0], $cmd);
    return $src if $src->{'err'};

    my $dest = file_find ($parms->[1], $cmd);
    return $dest if $dest->{'err'};

    # Ignore if both src and dest are equal.
    return undef if $src->{'fname'} eq $dest->{'fname'};

    if (! -d $dest->{'dirname'}) {
	eval { File::Path::make_path ($dest->{'dirname'}, { mode => 0711 }) };
	if ($@ ne '') {
	    return cmderr ($cmd, $@);
	}
    }

    if (File::Copy::move ($src->{'fname'}, $dest->{'fname'})) {
	return undef;
    }
    return cmderr ($cmd, 'move: ' . $src->{'fname'} . ' ' . $dest->{'fname'} . ' ' . $!);
}

sub cmd_file_copy {
    my ($cmd, $num_parms, $parms, $fcgi) = @_;

    if ($num_parms != 2) {
	return { 'err' => 'CGI:CMDNUMPARAM', 'parms' => [ $cmd, 2, $num_parms ] };
    }

    my $src = file_find ($parms->[0], $cmd);
    return $src if $src->{'err'};

    my $dest = file_find ($parms->[1], $cmd);
    return $dest if $dest->{'err'};

    # Ignore if both src and dest are equal.
    return undef if $src->{'fname'} eq $dest->{'fname'};

    if (! -d $dest->{'dirname'}) {
	eval { File::Path::make_path ($dest->{'dirname'}, { mode => 0711 }) };
	if ($@ ne '') {
	    return cmderr ($cmd, $@);
	}
    }

    if (File::Copy::copy ($src->{'fname'}, $dest->{'fname'})) {
	return undef;
    }
    return cmderr ($cmd, 'copy: ' . $src->{'fname'} . ' ' . $dest->{'fname'} . ' ' . $!);
}

my %CMD_PROC = 
    (
     'FILE_CREATE' => \&cmd_file_create,
     'FILE_DELETE' => \&cmd_file_delete,
     'FILE_MOVE' => \&cmd_file_move,
     'FILE_COPY' => \&cmd_file_copy
    );

# returns undef if success, or an error hashref to be sent to error_send.
sub info_handler {
    my $fcgi = shift;
    my $raise = shift;

    my $cmd = $raise->{'type'};
    my $parms = $raise->{'parms'};

    my $proc = $CMD_PROC{$cmd};
    if (!$proc) {
	return { 'err' => 'CGI:CMDUNK', 'parms' => [ $cmd ] };
    }

    return &$proc ($cmd, scalar @$parms, $parms, $fcgi);
}
