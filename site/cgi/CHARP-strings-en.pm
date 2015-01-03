package CHARP;

use utf8;

%ERROR_DESCS = (
    'DBI:CONNECT'	=> 'Database could not be contacted.',
    'DBI:PREPARE'	=> 'SQL sentence preparation failed.',
    'DBI:EXECUTE'	=> 'SQL sentence execution failed.',
    'CGI:REQPARM'	=> 'Parameters required for HTTP request are missing.',
    'CGI:NOTPOST'	=> 'HTTP method is not type POST.',
    'CGI:PATHUNK'	=> 'Unknown HTTP path.',
    'CGI:BADPARAM'	=> '%s: Malformed parameters `%s`.',
    'CGI:NUMPARAM'	=> '%s: %s required parameters, %s delivered.',
    'CGI:BINDPARAM'	=> '%s: Parameter %s (`%s`) of `%s` could not be bound.',
    'CGI:FILESEND'	=> 'Error while sending file.',
    'CGI:CMDUNK'	=> 'CGI command `%s` unknown.',
    'CGI:CMDNUMPARAM'	=> 'CGI command %s: %s required parameters, %s delivered.',
    'CGI:CMDERR'	=> 'CGI command %s: execution error.',
    'SQL:USERUNK'	=> 'User `%s` with status `%s` not found.',
    'SQL:PROCUNK'	=> 'Function `%s` not found.',
    'SQL:REQUNK'	=> 'Request not found.',
    'SQL:REPFAIL'	=> 'Wrong signature. Verify your username and password.',
    'SQL:ASSERT'	=> 'Bad parameters (`%s`).',
    'SQL:USERPARAMPERM'	=> 'The user %s is not allowed to perform this operation.',
    'SQL:USERPERM'	=> 'Your account does not have the required permissions to perform this operation.',
    'SQL:MAILFAIL'	=> 'An error ocurred while sending an email to <%s>. Please check that the address is correct.',
    'SQL:DATADUP'	=> 'The data could not be inserted due to duplicity errors.',
    'SQL:NOTFOUND'	=> 'Information not found.',
    'SQL:EXIT'		=> '%s'
);

%STRS = (
    'CGI:FILESEND:MISSING:MSG' => '%s: Missing `filename` parameter.',
    'CGI:FILESEND:OPENFAIL:MSG' => '%s: Error opening `%s` (%s).',
    'CGI:CMDERR:BADPATH' => 'Invalid path `%s`.',
    'CGI:CMDERR:PATHNOTFOUND' => 'Path `%s` not found.'
);    

1;
