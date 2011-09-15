// This file is part of the CHARP project.
//
// Copyright © 2011
//   Free Software Foundation Europe, e.V.,
//   Talstrasse 110, 40217 Dsseldorf, Germany
//
// Licensed under the EUPL V.1.1. See the file LICENSE.txt for copying conditions.

(function () {
    var cache = {};

    function fetch_success (data, ctx) {
	var path = ctx.path;
	var parent;
	var node = cache;
	for (var i = 0, key; key = path[i]; i++) {
	    if (!node[key] && path[i + 1])
		node[key] = {};
	    parent = node;
	    node = node[key];
	}
	parent[path.pop ()] = data;

	ctx.cb (data);
    }

    function fetch_from_cache (path) {
	var parent;
	var node = cache;
	for (var i = 0, key; key = path[i]; i++) {
	    node = node[key];
	    if (!node)
		return undefined;
	}
	return node;
    }

    var mod = function (proc, area, params, asAnon, cb) {
	if (!params)
	    params = [];
	var path = [area, proc].concat (params);
	var data = fetch_from_cache (path);
	if (data)
	    cb (data);
	else
	    APP.charp.request (proc, params, { success: fetch_success, cb: cb, path: path, asAnon: asAnon });
    };

    mod.init = function () {
	    mod.initialized = true;
    };

    mod.cacheDump = function (area) {
	if (!area)
	    cache = {};
	else if (mod.cache[area])
	    cache[area] = {};
    };

    if (APP.DEVEL)
	mod.cache = cache;
	
    APP.fetch = mod;
}) ();
