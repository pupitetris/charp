package CHARP;

$DB_NAME = 'myproject';
$DB_HOST = 'localhost';
$DB_PORT = '5432';
$DB_USER = 'postgres';
$DB_PASS = '<<<YOUR DB PASSWORD HERE>>>';

# This works with both Pg and mysql:
$DB_STR = "database=$DB_NAME;host=$DB_HOST;port=$DB_PORT";
undef $DB_NAME;
undef $DB_HOST;
undef $DB_PORT;

# Postgres: To set up a service connection file (best practice).
# http://search.cpan.org/dist/DBD-Pg/Pg.pm#connect
# Remove variable declarations above and uncomment:
#
# $ENV{'PGSYSCONFDIR'} = '/var/blahblah/my_pg_service.conf';
# $DB_STR = '';
# $DB_USER = '';
# $DB_PASS = '';

# MySQL: use mysql
$DB_DRIVER = 'Pg';

# Language for the localized strings.
$CHARP_LANG = 'en';

1;
