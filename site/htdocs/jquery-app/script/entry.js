// This file is part of the CHARP project.
//
// Copyright © 2011 - 2014
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

// Entry point processing module. Entry point URLs come with a fragment part (#frag) which 
// contains a signature provided by the server. When loading, we ask the server to check that 
// the URL corresponds to the signature to prevent argument forging. 
//
// Another required argument is 't', a timestamp that requires credentials to be reissued
// if it is stale (change _TIMEOUT value to configure validity
//
// If everything is correct, the requested module is loaded and control is handed to it.

(function () {

    var _TIMEOUT = 30 * 60 * 1000; // milisecs
    var _sevSupport = 'Contacte a soporte para reportar el problema.';

    var mod = {
	init: function () {
	    mod.initialized = true;

	    if (!APP.args || !APP.args.module || !APP.args.login || !APP.args.t)
		return APP.msgDialog ({ icon: 'stop', 
					title: 'Error en parámetros de página.', 
					desc: 'Los parámetros para esta página están mal formados', 
					sev: _sevSupport });

	    if (new Date ().getTime () - APP.args.t > _TIMEOUT) {
		APP.charp.credentialsDelete ();
		return APP.msgDialog ({ icon: 'stop', 
					title: 'Sesión expirada.', 
					desc: 'Esta sesión ha expirado ya.', 
					sev: 'Vuelva a abrir esta ventana desde el menú.' });
	    }
	    
	    APP.charp.credentialsLoad ();
	    if (APP.charp.login && APP.charp.login == APP.args.login)
		return mod.checkUrl ();

	    APP.loadModule ('login');
	},

	checkUrl: function () {
	    APP.charp.request ('check_url', [window.location.toString ()], 
			       { 
				   success: function (data) {
				       if (data && data[0].success)
					   APP.loadModule (APP.args.module, null, function () { 
					       APP.msgDialog ({ icon: 'error', 
								title: 'Módulo no encontrado.',
								desc: 'El módulo `' + APP.args.module + '` no existe.', 
								sev: _sevSupport });
					   });
				       else
					   APP.msgDialog ({ icon: 'stop',
							    title: 'Firma equivocada.',
							    desc: 'La firma de los parámetros no es válida.',
							    sev: _sevSupport });
				   },
				   error: function (err) {
				       switch (err.key) {
				       case 'SQL:REPFAIL':
				       case 'SQL:USERUNK':
					   APP.loadModule ('login');
					   return;
				       }
				       return true; // call fallback handler.
				   },
				   complete: function () {
				       if (APP.login)
					   APP.login.loginButtonReset ();
				   }
			       });
	}
    };

    APP.args = APP.argsParse ();
    APP.entry = mod;
}) ();
