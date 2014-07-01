// This file is part of the CHARP project.
//
// Copyright © 2011 - 2014
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

function CHARP () {
    this.BASE_URL = window.location.protocol + '//' + window.location.hostname + (window.location.port? ':' + window.location.port: '') + '/';
};

CHARP.ERROR_SEV = {
    INTERNAL: 1,
    PERM: 2,
    RETRY: 3,
    USER: 4,
    EXIT: 5
};

CHARP.ERROR_LEVELS = {
    DATA : 1,
    SQL  : 2,
    DBI  : 3,
    CGI  : 4,
    HTTP : 5,
    AJAX : 6
};

CHARP.ERRORS = {
    'HTTP:CONNECT': {
	code: -1,
	sev: CHARP.ERROR_SEV.RETRY,
    },
    'HTTP:SRVERR': {
	code: -2,
	sev: CHARP.ERROR_SEV.INTERNAL,
    },
    'AJAX:JSON': {
	code: -3,
	sev: CHARP.ERROR_SEV.INTERNAL,
    },
    'AJAX:UNK': {
	code: -4,
	sev: CHARP.ERROR_SEV.INTERNAL,
    }
};

(function () {
    for (var key in CHARP.ERRORS) {
	var lvl = key.split (':')[0];
	var err = CHARP.ERRORS[key];
	err.level = CHARP.ERROR_LEVELS[lvl];
	err.key = key;
    }
}) ();

CHARP.prototype = {
    handleError: function (err, ctx) {
	if (ctx) {
	    if (!err.ctx)
		err.ctx = ctx;
	    if (ctx.error && !ctx.error (err, ctx, this))
		return;
	}

	return APP.msgDialog ({ icon: (err.sev < 3)? 'error': 'warning',
				desc: err.desc,
				msg: '<><pre>' + err.ctx.reqData.res + ': ' + err.statestr + 
				     ((err.state)? ' (' + err.state + ')' : '') + 
				     ((err.msg)? '<br />' + err.msg : '') +
				     '</pre>',
				sev: CHARP.ERROR_SEV_MSG[err.sev],
				title: 'Error ' + err.key + '(' + err.code + ')',
				opts: {
				    resizable: true,
				    height: 'auto',
				    minHeight: 250,
				    maxHeight: 400,
				    width: 500,
				    minWidth: 500,
				    maxWidth: 800
				} });
    },

    handleAjaxStatus: function (req, status, ctx) {
	var err;
	switch (status) {
	case 'success':
	    return;
	case 'error':
	    err = CHARP.extendObj ({ msg: 'Error HTTP: ' + req.statusText + ' (' + req.status + ').' }, CHARP.ERRORS['HTTP:SRVERR']);
	    break;
	case 'parsererror':
	    err = CHARP.ERRORS['AJAX:JSON'];
	    if (APP.DEVEL)
		err = CHARP.extendObj ({ msg: 'Datos: `' + req.responseText + '`.' }, err);
	    break;
	default:
	    err = CHARP.extendObj ({ msg: 'Error desconocido: (' + status + ').' }, CHARP.ERRORS['AJAX:UNK']);
	}
	this.handleError (err, ctx);
    },

    replySuccess: function (data, status, req, ctx) {
	switch (status) {
	case 'success':
	    if (!data)
		return this.handleError (CHARP.ERRORS['AJAX:JSON'], ctx);
	    if (data.error)
		return this.handleError (data.error, ctx);
	    if (ctx.success) {
		if (data.fields && data.data) {
		    if (data.fields.length == 1 && data.fields[0] == 'rp_' + ctx.reqData.res)
			data = data.data[0][0];
		    else if (!ctx.asArray) {
			data.res = [];
			for (var i = 0, d; d = data.data[i]; i++) {
			    var o = {};
			    for (var j = 0, f; f = data.fields[j]; j++)
				o[f] = d[j];
			    data.res.push (o);
			}
			data = data.res;
		    }
		}
		return ctx.success (data, ctx, this, req);
	    }
	    break;
	}
    },

    replyComplete: function (req, status, ctx) {
	if (ctx.complete)
	    ctx.complete (status, ctx, req);

	this.handleAjaxStatus (req, status, ctx);
    },

    reply: function (chal, ctx) {
	var url = this.BASE_URL + 'reply';

	var sha = new jsSHA (this.login.toString () + chal.toString () + this.passwd.toString (), 'ASCII');
	var hash = sha.getHash ('SHA-256', 'HEX');
	var params = {
	    login: this.login,
	    chal: chal,
	    hash: hash
	};

	if (ctx.charpReplyHandler)
	    return ctx.charpReplyHandler (url + '?' + CHARP.paramsUriEncode (params), ctx);

	var charp = this;
	CHARP.ajaxPost (url, params, 
			function (data, status, req) { return charp.replySuccess (data, status, req, ctx); },
			function (req, status) { return charp.replyComplete (req, status, ctx); });
    },

    requestSuccess: function (data, status, req, ctx) {
	if (ctx.asAnon)
	    return this.replySuccess (data, status, req, ctx);

	if (req.status == 0 && req.responseText == "")
	    this.handleError (CHARP.ERRORS['HTTP:CONNECT'], ctx);
	if (status == 'success') {
	    if (data.error)
		return this.handleError (data.error, ctx);
	    if (data && data.chal)
		this.reply (data.chal, ctx);
	}
    },
    
    requestComplete: function (req, status, ctx) {
	if (ctx.req_complete)
	    ctx.req_complete (status, ctx, req);

	this.handleAjaxStatus (req, status, ctx);
    },

    request: function (resource, params, ctx) {
	if (!ctx)
	    ctx = {};
	else if (typeof ctx == 'function')
	    ctx = {success: ctx};

	var data = {
	    login: this.login,
	    res: resource,
	    params: JSON.stringify (params)
	};

	if (this.login == '!anonymous')
	    ctx.asAnon = true;

	if (ctx.asAnon)
	    data.anon = 1;

	ctx.reqData = data;

	var charp = this;
	CHARP.ajaxPost (this.BASE_URL + 'request', data, 
			function (data, status, req) { return charp.requestSuccess (data, status, req, ctx); },
			function (req, status) { return charp.requestComplete (req, status, ctx); });
    },

    credentialsSet: function (login, passwd_hash) {
	this.login = login;
	this.passwd = passwd_hash;
    },

    credentialsSave: function () {
	localStorage.setItem ('charp_login', this.login);
	localStorage.setItem ('charp_passwd', this.passwd);
    },

    credentialsLoad: function () {
	this.login = localStorage.getItem ('charp_login');
	this.passwd = localStorage.getItem ('charp_passwd');
	return this.login;
    },
    
    credentialsDelete: function () {
	localStorage.removeItem ('charp_login');
	localStorage.removeItem ('charp_passwd');
   },
    
    init: function (login, passwd_hash) {
	this.credentialsSet (login, passwd_hash);
	return this;
    }
};
