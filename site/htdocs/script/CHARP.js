// This file is part of the CHARP project.
//
// Copyright © 2011
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

function CHARP () {
};

CHARP.prototype = {
    BASE_URL: window.location.protocol + '//' + window.location.hostname + (window.location.port? ':' + window.location.port: '') + '/',

    ERROR_SEV: {
	INTERNAL: 1,
	PERM: 2,
	RETRY: 3,
	USER: 4,
	EXIT: 5
    },

    ERROR_SEV_MSG: [
	undefined,
	'Este es un error interno en el sistema. Por favor anote la información proporcionada en este mensaje y llame a soporte para que se trabaje en una solución.',
	'Está tratando de acceder a datos a los que no tiene autorización. Si requiere mayor acceso, llame a soporte.',
	'Este es un error temporal, por favor vuelva a intentar inmediatamente o en unos minutos. Si el error persiste, llame a soporte.',
	'La información que proporcionó es errónea, por favor corrija sus datos y vuelva a intentar.',
	'Este es un mensaje de resultado proporcionado por la aplicación'
    ],

    ERROR_LEVELS: {
	DATA: 1,
	SQL: 2,
	DBI: 3,
	CGI: 4,
	HTTP: 5,
	AJAX: 6
    },

    handleError: function (err, ctx) {
	if (ctx) {
	    if (!err.ctx)
		err.ctx = ctx;
	    if (ctx.error && !ctx.error (err, ctx, this))
		return;
	}

	return APP.msgDialog ({ icon: (err.sev < 3)? 'error': 'warning',
				desc: err.desc,
				msg: '<><pre>' + err.ctx.reqData.res + ': ' + err.statestr + ' (' + err.state + ')<br />' + err.msg + '</pre>',
				sev: this.ERROR_SEV_MSG[err.sev],
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
	    err = $.extend ({ msg: 'Error HTTP: ' + req.statusText + ' (' + req.status + ').' }, this.ERRORS['HTTP:SRVERR']);
	    break;
	case 'parsererror':
	    err = this.ERRORS['AJAX:JSON'];
	    if (APP.DEVEL)
		err = $.extend ({ msg: 'Datos: `' + req.responseText + '`.' }, err);
	    break;
	default:
	    err = $.extend ({ msg: 'Error desconocido: (' + status + ').' }, this.ERRORS['AJAX:UNK']);
	}
	this.handleError (err, ctx);
    },

    replySuccess: function (data, status, req, ctx) {
	switch (status) {
	case 'success':
	    if (!data)
		return this.handleError (this.ERRORS['AJAX:JSON'], ctx);
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
	    return ctx.charpReplyHandler (url + '?' + $.param (params), ctx);

	var charp = this;
	$.ajax ({
	    type: 'POST',
	    url: url,
	    cache: false,
	    data: params,
	    dataType: 'json',
	    global: false,
	    complete: function (req, status) { return charp.replyComplete (req, status, ctx); },
	    success: function (data, status, req) { return charp.replySuccess (data, status, req, ctx); }
	});
    },

    requestSuccess: function (data, status, req, ctx) {
	if (ctx.asAnon)
	    return this.replySuccess (data, status, req, ctx);

	if (req.status == 0 && req.responseText == "")
	    this.handleError (this.ERRORS['HTTP:CONNECT'], ctx);
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
	var charp = this;

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

	$.ajax ({
	    type: 'POST',
	    url: this.BASE_URL + 'request',
	    cache: false,
	    data: data,
	    dataType: 'json',
	    global: false,
	    complete: function (req, status) { return charp.requestComplete (req, status, ctx); },
	    success: function (data, status, req) { return charp.requestSuccess (data, status, req, ctx); }
	});
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

(function () {
    CHARP.prototype.ERRORS = {
	'HTTP:CONNECT': {
	    code: -1,
	    sev: CHARP.prototype.ERROR_SEV.RETRY,
	    desc: 'No fue posible contactar al servicio web.',
	    msg: 'Verifique que su conexión a internet funcione y vuelva a intentar.'
	},
	'HTTP:SRVERR': {
	    code: -2,
	    sev: CHARP.prototype.ERROR_SEV.INTERNAL,
	    desc: 'El servidor web respondió con un error.'
	},
	'AJAX:JSON': {
	    code: -3,
	    sev: CHARP.prototype.ERROR_SEV.INTERNAL,
	    desc: 'Los datos obtenidos del servidor están mal formados.'
	},
	'AJAX:UNK': {
	    code: -4,
	    sev: CHARP.prototype.ERROR_SEV.INTERNAL,
	    desc: 'Un tipo de error no reconocido ha ocurrido.'
	}
    };

    for (var key in CHARP.prototype.ERRORS) {
	var lvl = key.split (':')[0];
	var err = CHARP.prototype.ERRORS[key];
	err.level = CHARP.prototype.ERROR_LEVELS[lvl];
	err.key = key;
    }
}) ();
