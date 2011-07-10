#!/usr/bin/perl

use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha256_hex);
use LWP::UserAgent;
use JSON::XS;
use utf8;

use Data::Dumper;

use URI::Escape;

$BASEURL = $ARGV[0];
$LOGIN = uri_escape ($ARGV[1]);
$PASSWD = uri_escape ($ARGV[2]);
$FUNC = uri_escape ($ARGV[3]);
$PARAMS = uri_escape ($ARGV[4]);

$ua = LWP::UserAgent->new;

$req = HTTP::Request->new (POST => "${BASEURL}/request");
$req->content ("login=$LOGIN&res=$FUNC&params=$PARAMS");

$res = $ua->request ($req);

if (! $res->is_success) {
    print "Error HTTP en request\n";
    print Dumper ($res->headers);
    exit 1;
}

$json = JSON::XS->new->utf8;
$s = eval { $json->decode ($res->content) };

if (!defined $s || ref $s ne 'HASH') {
    print "Error decode JSON en request\n";
    print $@ . "\n";
    print $res->content . "\n";
    exit 2;
}

if ($s->{'error'}) {
    print "Error reportado en request\n";
    print $res->content . "\n";
    exit 3;
}

$chal = $s->{'chal'};
$hash = sha256_hex ($LOGIN, $chal, md5_hex ($PASSWD));

$rep = HTTP::Request->new (POST => "${BASEURL}/reply");
$rep->content ('login=' . $LOGIN . '&chal=' . $chal . '&hash=' . $hash);

$res = $ua->request ($rep);

if (! $res->is_success) {
    print "Error HTTP en reply\n";
    print Dumper ($res->headers);
    exit 4;
}

$s2 = eval { $json->decode ($res->content) };
if (!defined $s2 || ref $s2 ne 'HASH') {
    print "Error decode JSON en reply\n";
    print $@ . "\n";
    print $res->content . "\n";
    exit 5;
}

if ($s2->{'error'}) {
    print "Error reportado en reply\n";
    print $res->content . "\n";
    exit 6;
}

print $res->content . "\n"; 
