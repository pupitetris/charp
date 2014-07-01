// This file is part of the CHARP project.
//
// Copyright © 2011 - 2014
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

CHARP.extendObj = function (obj, add) {
    return $.extend ({}, obj, add);
}

CHARP.paramsUriEncode = function (params) {
    return $.param (params);
}

CHARP.ajaxPost = function (url, params, successCb, completeCb) {
    $.ajax ({ 
	type: 'POST',
	url: url,
	cache: false,
	data: params,
	dataType: 'json',
	global: false,
	success: successCb,
	complete: completeCb,
    });
}
