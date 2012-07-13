using System;
using System.Net; // for WebClient
using System.Collections.Generic; // for Dictionary
using System.Collections.Specialized; // for NameValueCollection
using Mono.Unix; // for Catalog

namespace monoCharp
{
	public abstract class Charp
	{
		public enum ERR_SEV {
			INTERNAL = 1,
			PERM,
			RETRY,
			USER,
			EXIT
		};
		
		public enum ERR_LEVEL {
			DATA = 1,
			SQL,
			DBI,
			CGI,
			HTTP,
			AJAX
		}
		
		private struct CharpError {
			public int code;
			public ERR_SEV sev;
			public string desc;
			public string msg;
			public ERR_LEVEL lvl;
			public string key;
			public int state;
			public string statestr;
		}
		
		private enum ERR {
			HTTP_CONNECT = 0,
			HTTP_SRVERR,
			AJAX_JSON,
			AJAX_UNK,
			HTTP_CANCEL,
			DATA_BADMSG
		}

		public delegate void CharpCtxSuccess (object data, UploadValuesCompletedEventArgs status, CharpCtx ctx);
		public delegate void CharpCtxReqComplete (UploadValuesCompletedEventArgs status, CharpCtx ctx);
		public delegate void CharpCtxError (CharpError err, CharpCtx ctx);

		private struct CharpCtx {
			// Set by you
			public CharpCtxSuccess success;
			public CharpCtxReqComplete req_complete;
			public CharpCtxError error;
			public bool asAnon = false;
			public object obj; // your stuff here.

			// Set by CHARP
			public NameValueCollection reqData;
			public Charp charp;
			public WebClient wc;
		}

		static public string BASE_URL = null;
		static private string[] ERR_SEV_MSG = null;
		static private CharpError[] ERRORS = null;

		public string baseUrl;
		private string login;

		static Charp ()
		{
			Catalog.Init ("monoCharp", "./locale");

			if (ERR_SEV_MSG == null) { // This to avoid warning.
				ERR_SEV_MSG = new string[] {
					null,
					Catalog.GetString ("This is an internal system error. Please take note of the provided information in this message and call support so a solution can be worked on."),
					Catalog.GetString ("You are trying to access unauthorized data. If you require adequate access, call support."),
					Catalog.GetString ("This is a temporary error, please try again immediately or in a few minutes. If the error persists, call support."),
					Catalog.GetString ("The provided information is invalid, please ammend the data and try again."),
					Catalog.GetString ("This message is a result value provided by the application.")
				};
			}
			
			if (ERRORS == null) { // This to avoid warning
				ERRORS = new CharpError[] {
					new CharpError { key = "HTTP:CONNECT", code = -1, sev = ERR_SEV.RETRY, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("Impossible to contact the web service."), 
						msg = Catalog.GetString ("Verify that your network connection works and try again.") },
					new CharpError { key = "HTTP:SRVERR", code = -2, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("The web server replied with an error."), msg = null },
					new CharpError { key = "AJAX:JSON", code = -3, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.AJAX,
						desc = Catalog.GetString ("D#ifata obtained from the web server are malformed."), msg = null },
					new CharpError { key = "AJAX:UNK", code = -4, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.AJAX,
						desc = Catalog.GetString ("An unknown error type has occurred."), msg = null },
					new CharpError { key = "HTTP:CANCEL", code = -5, sev = ERR_SEV.RETRY, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("The connection with the web service was cancelled."), 
						msg = Catalog.GetString ("A web service operation was cancelled. Please verify that your network is in working order.") },
					new CharpError { key = "DATA:BADMSG", code = -6, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.DATA,
						desc = Catalog.GetString ("The JSON web service response is invalid."), msg = null }
				};
			}
		}
		
		public Charp ()
		{
			init ();
		}

		public Charp (string login, string passwdHash)
		{
			init ();
		}

		private void init ()
		{
			baseUrl = BASE_URL;
		}

		public abstract void handleError (CharpError err, CharpCtx ctx = null);

		public void handleError (Dictionary<string, object> err, CharpCtx ctx = null)
		{
			CharpError cerr = new CharpError {
				code = (int) err["code"],
				sev = (int) err["sev"],
				desc = (string) err["desc"],
				msg = (string) err["msg"],
				lvl = (int) err["lvl"],
				key = (string) err["key"],
				state = (int) err["state"],
				statestr = (string) err["statestr"]
			};

			handleError (cerr, ctx);
		}

		private void replySuccess (Dictionary<string, object> data, UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{

		}

		private void reply (string chal, CharpCtx ctx)
		{

		}

		private void requestSuccess (UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (status.Result == null || status.Result.Length == 0) {
				handleError (ERRORS [ERR.HTTP_CONNECT], ctx);
				return;
			}

			Dictionary<string, object> data;
			try {
				data = JSON.decode (status.Result);
			} catch (Exception e) {
				CharpError err = ERRORS [ERR.AJAX_JSON];
				err.msg = String.Format (Catalog.GetString ("JSON decode error: {0}"), e.Message);
				handleError (err, ctx);
				return;
			}
			
			if (data.ContainsKey ("error")) {
				handleError (data ["error"], ctx);
				return;
			}

			if (ctx.asAnon) {
				replySuccess (data, status, ctx);
				return;
			}

			if (data.ContainsKey ("chal")) {
				reply (data ["chal"], ctx);
				return;
			}

			handleError (ERRORS [ERR.DATA_BADMSG], ctx);
		}

		// TODO: ver si podemos poner esta como private.
		public static void requestCompleteH (object sender, UploadValuesCompletedEventArgs status)
		{
			CharpCtx ctx = status.UserState;
			Charp charp = ctx.charp;
			
			if (status.Cancelled) {

				charp.handleError (ERRORS [ERR.HTTP_CANCEL], ctx);

			} else if (status.Error != null) {

				CharpError err = ERRORS [ERR.HTTP_SRVERR];
				err.msg = String.Format (Catalog.GetString ("HTTP error: {0}."), status.Error.Message);
				charp.handleError (err, ctx);

			} else {

				charp.requestSuccess (status, ctx);

			}

			if (ctx.req_complete)
				ctx.req_complete (status, ctx);
		}

		public void request (string resource, object[] parms, CharpCtx ctx = null)
		{
			if (ctx == null) {
				ctx = new CharpCtx ();
			} 

			if (login == "!anonymous") {
				ctx.asAnon = true;
			}

			NameValueCollection data = new NameValueCollection ();
			data["login"] = login;
			data["res"] = resource;
			data["anon"] = ctx.asAnon? "1": "0";
			data["params"] = JSON.encode (parms);

			ctx.reqData = data;
			ctx.charp = this;
			ctx.wc = new WebClient ();
			ctx.wc.UploadValuesCompleted += new UploadValuesCompletedEventHandler (requestCompleteH);
			ctx.wc.UploadValuesAsync (baseUrl + "request", "POST", data, ctx);
		}
	}
}
