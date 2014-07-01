// This file is part of the CHARP project.
//
// Copyright © 2011 - 2014
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

CHARP.ERRORS['HTTP:CONNECT'].desc	= 'Web service could not be reached.';
CHARP.ERRORS['HTTP:CONNECT'].msg	= 'Check that your internet connection is working properly and try again.';
CHARP.ERRORS['HTTP:SRVERR'].desc	= 'The web server replied with an error.';
CHARP.ERRORS['AJAX:JSON'].desc		= 'Data obtained from the server are malformed.';
CHARP.ERRORS['AJAX:UNK'].desc		= 'An unrecognized error has occurred.';

CHARP.ERROR_SEV_MSG = [
    undefined,
    /* INTERNAL */ 'This is an internal system error. Please take note of the information provided in this message and contact support so a solution can be implemented.',
    /* PERM */     'You are trying to fetch unauthorized data. If greater access is required, contact support.',
    /* RETRY */    'This is a temporal error, please try again immediately or in a few minutes. If the error persists, contact support.',
    /* USER */     'The information you provided is incorrect. Please correct your data and try again.',
    /* EXIT */     'This is a result message sent for application handling and should not be visible to the user.'
];
