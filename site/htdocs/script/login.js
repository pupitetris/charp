// This file is part of the CHARP project.
//
// Copyright © 2011
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

// Módulo de ejemplo que presenta un diálogo de entrada.
(function () {

    function loadCredentials () {
	APP.charp.credentialsLoad ();
	if (APP.charp.login) {
	    $('#login-username').val (APP.charp.login);
	    $('#login-passwd').val (APP.charp.passwd);
	}
    }

    var mod = {
	init: function () {
	    mod.initialized = true;

	    var div = document.createElement ('div');
	    div.id = 'login';
	    div.className = 'page';
	    $('body').append (div);
	    APP.loadLayout ($(div), 'login.html', layoutInit);

	    APP.charp = new CHARP ().init ();
	},

	onLoad: function () {
	    if (!mod.loaded)
		return;

	    mod.reset ();
	    loadCredentials ();
	    $('#login-username').focus ();
	},

	reset: function () {
	    loginButtonReset ();

	    clearInputs ();

	    APP.charp.credentialsSet ();
	}
    };

    function loginButtonReset () {
	APP.buttonBusy ($('#login-button'), false);
    }

    function clearInputs () {
/*	$('#login-username,#login-passwd')
	    .val ('')
	    .blur ();*/
    }

    function layoutInit () {
	var loginButton = $('#login-button');
	var fileButton = $('#file-button');

	function login_success (data, ctx, charp, req) {
	    if (data) {
		alert ('Autentificación exitosa.');
		APP.buttonBusy (loginButton, false);
	    }
	}
	
	function login_error (err, ctx, charp) {
	    loginButtonReset ();

	    switch (err.key) {
	    case 'SQL:USERUNK':
		$('#login-username').addClass ('error');
		$('#login-username').after ('<span class="error login-error">Usuario no encontrado. ¿Escribió bien su nombre de usuario?</span>');
		break;
	    case 'SQL:REPFAIL':
		$('#login-passwd').addClass ('error');
		$('#login-passwd').after ('<span class="error login-error">Contraseña incorrecta.</span>');
		break;
	    default:
		return charp.handleError (err);
	    }
	}

	var form = $('.login-form form');

	function loginSubmit () {
	    if (validator.form ()) {
		APP.buttonBusy (loginButton, true);
		APP.charp.credentialsSet ($('#login-username').val (), MD5 ($('#login-passwd').val ()));
		APP.charp.request ('user_auth', [], 
				   { 
				       success: login_success,
				       error: login_error,
				   });
	    }
	    return false;
	}

	var validator = form.validate ({
	    rules: {
		username: 'required',
		passwd: 'required'
	    },
	    messages: {
		username: 'Escriba su nombre de usuario.',
		passwd: 'Por favor escriba su contraseña.'
	    },
	    errorElement: 'span'
	});

	form.bind ('submit', loginSubmit);

	loginButton
	    .button ()
	    .bind ('click', loginSubmit);

	function loginFocus () {
	    var errors = $('.login-error', $(this).parent ());
	    if (errors.length > 0) {
		errors.remove ();
		$(this).removeClass ('error');
	    }
	    return true;
	}

	$('#login-username,#login-passwd')
	    .bind ('focus', loginFocus)
	    .bind ('keyup', function (ev) { if (ev.keyCode == 13) loginSubmit (); });

	function fileButtonClick () {
	    if (!APP.charp.login)
		return alert ('Primero inicie sesión.');

	    APP.charp.request ('file_image_test', [$('#file-filename').val ()], { 
		charpReplyHandler: function (url, ctx) {
		    $('#file-img').attr ('src', url);
		}
	    });
	}

	fileButton
	    .button ()
	    .bind ('click', fileButtonClick);

	$('#anon-button')
	    .bind ('click', function () {
		APP.charp.request ('get_random_bytes', ['hola', 'adios'], { asAnon: true, 
							     success: function (data) {
								 $('#anon-button').text ('Request anónimo: ' + data[0].random);
							     } });
	    });

	$('#save-button')
	    .bind ('click', function () {
		APP.charp.credentialsSet ($('#login-username').val (), MD5 ($('#login-passwd').val ()));
		APP.charp.credentialsSave ();
	    });

	$('#load-button')
	    .bind ('click', function () {
		loadCredentials ();
	    });

	$('#del-button')
	    .bind ('click', function () {
		APP.charp.credentialsDelete ();
		$('#login-username,#login-passwd')
		    .val ('');
	    });

	mod.loaded = true;
	mod.onLoad ();
    }

    APP.login = mod;
}) ();