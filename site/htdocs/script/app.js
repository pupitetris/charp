// This file is part of the CHARP project.
//
// Copyright © 2011
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

(function () {
    function msgDialogAppendP (parent, contents, className) {
	if (contents && typeof contents.selector != 'undefined') {
	    contents.addClass (className);
	    if (parent)
		parent.append (contents);
	    return contents;
	}
	
	var p = $('<p />');
	if (className)
	    p.addClass (className);

	if (contents) {
	    if (contents.indexOf ('<>') == 0)
		p.html (contents.substr (2));
	    else
		p.text (contents);
	}

	if (parent)
	    parent.append (p);
	return p;
    }

    window.APP = APP = {
	extendClass: function (childClass, superClass) {
	    childClass.prototype.__proto__ = superClass.prototype;
	},

	loadModule: function (name, cb, errCb) {
	    if (APP[name]) {
		if (!APP[name].initialized && APP[name].init) {
		    APP[name].MOD_NAME = name;
		    APP[name].init ();
		}
		if (APP[name].onLoad)
		    APP[name].onLoad ();
		if (cb) cb (APP[name]);
	    } else {
		var add = '';
		if (APP.DEVEL)
		    add = '?' + Math.random ().toString ().substr (2);
		else
		    add = '?' + APP.VERSION;
		$.ajax ({ dataType: 'script',
			     url: 'script/' + name + '.js' + add, 
			     success: function () {
				 if (APP[name] && APP[name].init) {
				     APP[name].MOD_NAME = name;
				     APP[name].init ();
				 }
				 if (cb) cb (APP[name]);
			     },
			     error: (errCb)? errCb:
			     function () {
				 APP.msgDialog ({ icon: 'error',
						  title: 'Error al cargar módulo.',
						  desc: 'El módulo `' + name + '` tuvo problemas al cargar.',
						  sev: 'Contacte a soporte para reportar el problema.'
						});
			     }
			});
	    }
	},

	loadLayout: function (jq_div, html_file, cb) {
	    var add = '';
	    if (APP.DEVEL)
		add = '?' + Math.random ().toString ().substr (2);
	    else
		add = '?' + APP.VERSION;

	    jq_div.load ('pages/' + html_file + add, cb);
	},

	setTitle: function (text) {
	    var str = '';
	    if (text && text != '')
		str = ' - ' + text.toString ();
	    $('title').text (APP.title + str);
	},

	eleBusy: function (ele, setBusy, append) {
	    if (setBusy) {
		var html = '<img class="spinner" src="img/spinner.gif" />';
		if (append)
		    ele.append (html);
		else
		    ele.prepend (html);
		ele.addClass ('busy');
	    } else {
		$('img.spinner', ele).remove ();
		ele.removeClass ('busy');
	    }
	},

	buttonBusy: function (button, setBusy, append) {
	    if (setBusy === undefined)
		setBusy = true;
	    if (append === undefined)
		append = true;

	    if (setBusy) {
		button.button ('disable');
		APP.eleBusy ($('.ui-button-text', button), true, append);
	    } else {
		button.button ('enable');
		button.mouseout ();
	    }
	},

	mexDate2ISO: function (mex) {
	    return mex.replace (new RegExp ('([0-9]{2})/([0-9]{2})/([0-9]{4})'), '$3-$2-$1');
	},

	msgDialog: function (opts) {
	    var div = (opts.div)? opts.div: $('<div/>');

	    if (opts.icon)
		div.append ('<div class="icon"><img src="img/icons/' + opts.icon + '.png" alt="" /></div>');
	    if (opts.desc)
		msgDialogAppendP (div, opts.desc, 'desc');
	    if (opts.msg)
		msgDialogAppendP (div, opts.msg, 'msg');
	    if (opts.sev)
		msgDialogAppendP (div, opts.sev, 'error-sev');

	    if (div.parent ().length == 0)
		$('body').append (div);

	    var dialogOpts = $.extend ({
		title: opts.title,
		draggable: false,
		modal: true,
		resizable: false,
		zIndex: 2000
	    }, opts.opts);

	    if (!dialogOpts.buttons)
		dialogOpts.buttons = { 'Cerrar': null };

	    function getButton (evt) {
		var node = $(evt.target);
		return (node.hasClass ('ui-button-text'))?
		    node.parent (): node;
	    }

	    function dialogClose (evt) {
		var button = getButton (evt);
		APP.msgDialogClose (div);
		if (opts.cb)
		    opts.cb ($(this), evt, opts);
	    }

	    $.each (dialogOpts.buttons, function (k, v) {
		var isArray = (dialogOpts.buttons.length !== undefined);
		var click_cb = (isArray)? v.click: v;

		var new_click_cb = function (evt) {
		    var res;
		    if (click_cb) res = click_cb (getButton (evt), div, opts);
		    if (res === undefined || res === true)
			dialogClose (evt);
		}

		if (isArray)
		    v.click = new_click_cb;
		else
		    dialogOpts.buttons[k] = new_click_cb;
	    });

	    div.dialog (dialogOpts);
	    return div;
	},

	msgDialogClose: function (div) {
	    div.dialog ('close');
	    div.remove ();
	},

	argsParse: function () {
	    var search = window.location.search;
            var args = {};
            var pairs = search.substr (1).split (/[;&]/);
            for (var i = 0, pair; pair = pairs[i]; i++) {
                var keyval = pair.split ("=");
                args[keyval[0]] = decodeURIComponent (keyval[1]);
            }
            return args;
	},

	title: "",
	DEVEL: true,
	VERSION: '0.5' // or whatever
    };

    $(document).ready (function () {
	// IE no tiene esta función.
	if (!Array.indexOf) {
	    Array.prototype.indexOf = function (obj) {
		for (var i = 0; i < this.length; i++)
	            if (this[i] == obj)
			return i;
		return -1;
	    }
	}

	if (!APP.DEVEL)
	    window.onbeforeunload = function () { return 'Por favor confirme que desea cerrar la aplicación.' };

	// This should be defined by you, it's your entry point.
	if (APP.main)
	    APP.main ();
    });
}) ();
