using System;
using System.Text; // for Encoding.UTF8
using System.Net; // for WebClient
using System.Collections.Specialized; // for NameValueCollection
using Mono.Unix; // for Catalog

namespace monoCHARP
{
	public abstract class CHARP : WebClient
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
		
		private struct charpError {
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
			HTTP_CANCEL
		}

		private enum charpStatus {
			IDLE,
			REQUEST,
			REPLY
		}
		
		public delegate void charpCtxSuccess (object data, charpCtx ctx, CHARP charp, WebRequest req);
		public delegate void charpCtxError (charpError err, charpCtx ctx, CHARP charp);

		private struct charpCtx {
			public bool asAnon = false;
			public NameValueCollection reqData;
			public charpCtxSuccess success;
			public charpCtxError error;
			public charpStatus status;
			public object obj;
		}

		static public string BASE_URL = null;
		static private string[] ERR_SEV_MSG = null;
		static private charpError[] ERRORS = null;

		public string baseUrl;
		private string login;

		static CHARP ()
		{
			Catalog.Init ("monoCHARP", "./locale");

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
				ERRORS = new charpError[] {
					new charpError { key = "HTTP:CONNECT", code = -1, sev = ERR_SEV.RETRY, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("Impossible to contact the web service."), 
						msg = Catalog.GetString ("Verify that your network connection works and try again.") },
					new charpError { key = "HTTP:SRVERR", code = -2, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("The web server replied with an error."), msg = null },
					new charpError { key = "AJAX:JSON", code = -3, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.AJAX,
						desc = Catalog.GetString ("D#ifata obtained from the web server are malformed."), msg = null },
					new charpError { key = "AJAX:UNK", code = -4, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.AJAX,
						desc = Catalog.GetString ("An unknown error type has occurred."), msg = null },
					new charpError { key = "HTTP:CANCEL", code = -5, sev = ERR_SEV.RETRY, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("The connection with the web service was cancelled."), 
						msg = Catalog.GetString ("A web service operation was cancelled. Please verify that your network is in working order.") },
				};
			}
		}
		
		public CHARP ()
		{
			init ();
		}

		public CHARP (string login, string passwdHash)
		{
			init ();
		}

		private void init ()
		{
			baseUrl = BASE_URL;
		}

		public abstract void handleError (charpError err, charpCtx ctx = null);

		public void OnUploadValuesCompleted (UploadValuesCompletedEventArgs e) // equivalent of handleAjaxStatus
		{
			base.OnUploadValuesCompleted (e);

			charpCtx ctx = e.UserState;

			if (e.Cancelled) {
				handleError (ERRORS [ERR.HTTP_CANCEL], ctx);
				return;
			}

			if (e.Error != null) {
				charpError err = ERRORS [ERR.HTTP_SRVERR];
				err.msg = String.Format (Catalog.GetString ("HTTP error: {0} ()."), e.Error.Message);
				handleError (err, ctx);
				return;
			}

			switch (ctx.status) {
			case charpStatus.IDLE:
				throw new Exception("Invalid CHARP status IDLE");
				break;
			case charpStatus.REQUEST:

				break;
			case charpStatus.REPLY:
				break;
			}
		}

		public void request (string resource, string[] parms, charpCtx ctx = null)
		{
			if (ctx == null) {
				ctx = new charpCtx ();
			} 

			if (login == "!anonymous") {
				ctx.asAnon = true;
			}

			ctx.status = charpStatus.REQUEST;

			NameValueCollection data = new NameValueCollection ();
			data["login"] = login;
			data["res"] = resource;
			data["anon"] = ctx.asAnon? "1": "0";
			data["params"] = JSON.encode (parms);

			ctx.reqData = data;

			UploadValuesAsync (baseUrl, "POST", data, ctx);
		}
	}
}

