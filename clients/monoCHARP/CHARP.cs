using System;
using System.Net; // for WebClient
using System.Text; // for Encoding.UTF8
using System.Collections; // for ArrayList
using System.Collections.Generic; // for Dictionary
using System.Collections.Specialized; // for NameValueCollection
using System.Security.Cryptography; // for SHA256Managed
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
		}
		
		public enum ERR_LEVEL {
			DATA = 1,
			SQL,
			DBI,
			CGI,
			HTTP,
			AJAX
		}
		
		public struct CharpError {
			public int code;
			public ERR_SEV sev;
			public string desc;
			public string msg;
			public ERR_LEVEL lvl;
			public string key;
			public string state;
			public string statestr;

			public string ToString (CharpCtx ctx = null) {
				StringBuilder b = new StringBuilder ();

				b.Append (((int)sev < 3)? Catalog.GetString ("Error"): Catalog.GetString ("Warning"));
				b.AppendFormat (Catalog.GetString (" {0}: \n{1}\n"), key, desc);
				if (ctx != null) { b.AppendFormat (Catalog.GetString ("{0}: "), ctx.reqData["res"]); }
				if (statestr != null) { b.Append (statestr); }
				if (state != "") { b.AppendFormat (Catalog.GetString (" ({0})"), state); }
				b.AppendFormat (Catalog.GetString ("{0}\n"), msg);
				b.AppendFormat (Catalog.GetString ("{0}\n"), ERR_SEV_MSG[(int) sev]);

				return b.ToString ();
			}
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
		public delegate void CharpCtxComplete (UploadValuesCompletedEventArgs status, CharpCtx ctx);
		public delegate void CharpCtxError (CharpError err, CharpCtx ctx);
		public delegate void CharpCtxReplyHandler (Uri base_uri, NameValueCollection parms, CharpCtx ctx);

		public class CharpCtx {
			// Set by you
			public CharpCtxSuccess success;
			public CharpCtxComplete complete;
			public CharpCtxComplete req_complete;
			public CharpCtxError error;
			public CharpCtxReplyHandler reply_handler;
			public bool asAnon;
			public bool asArray;
			public object obj; // your stuff here.

			// Set by CHARP
			public NameValueCollection reqData;
			public Charp charp;
			public WebClient wc;

			public CharpCtx () {
				asAnon = false;
				asArray = false;
			}
		}

		static public string BASE_URL = null;
		static private string[] ERR_SEV_MSG = null;
		static private CharpError[] ERRORS = null;
		static private SHA256Managed sha;

		public string baseUrl;
		private string login;
		private string passwd;

		static Charp ()
		{
			sha = new SHA256Managed ();

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
			this.login = login;
			this.passwd = passwdHash;
		}

		private void init ()
		{
			baseUrl = BASE_URL;
		}

		public abstract void handleError (CharpError err, CharpCtx ctx = null);

		public void handleError (Dictionary<string, object> err, CharpCtx ctx = null)
		{
			CharpError cerr = new CharpError {
				code = Int32.Parse ((string) err["code"]),
				sev = (ERR_SEV) Int32.Parse ((string) err["sev"]),
				desc = (string) err["desc"],
				msg = (string) err["msg"],
				lvl = (ERR_LEVEL) Int32.Parse ((string) err["level"]),
				key = (string) err["key"],
				state = (string) err["state"],
				statestr = (string) err["statestr"]
			};

			handleError (cerr, ctx);
		}

		private Dictionary<string, object> handleResult (UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (status.Cancelled) {
				handleError (ERRORS [(int) ERR.HTTP_CANCEL], ctx);
				return null;
			} 

			if (status.Error != null) {
				CharpError err = ERRORS [(int) ERR.HTTP_SRVERR];
				err.msg = String.Format (Catalog.GetString ("HTTP WebClient error: {0}"), status.Error.Message);
				handleError (err, ctx);
				return null;
			}

			if (status.Result == null || status.Result.Length == 0) {
				handleError (ERRORS [(int) ERR.HTTP_CONNECT], ctx);
				return null;
			}
			
			Dictionary<string, object> data;
			try {
				data = (Dictionary<string, object>) JSON.decode (status.Result);
			} catch (Exception e) {
				CharpError err = ERRORS [(int) ERR.AJAX_JSON];
				err.msg = String.Format (Catalog.GetString ("Error: {0}, Data: {1}"), 
				                         e.Message, Encoding.UTF8.GetString (status.Result));
				handleError (err, ctx);
				return null;
			}
			
			if (data.ContainsKey ("error")) {
				handleError ((Dictionary<string, object>) data ["error"], ctx);
				return null;
			}

			return data;
		}

		private void replySuccess (Dictionary<string, object> data, UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (ctx.success == null) {
				return;
			}
			
			if (!data.ContainsKey ("fields") || !data.ContainsKey ("data")) {
				handleError (ERRORS [(int) ERR.DATA_BADMSG], ctx);
			}

			object res;
			ArrayList fields = (ArrayList) data["fields"];
			ArrayList dat = (ArrayList) data["data"];

			if (fields.Count == 1 && (string) fields[0] == "rp_" + ctx.reqData["res"]) {
				res = (string) ((ArrayList) dat[0])[0];
			} else if (!ctx.asArray) {
				ArrayList arr = new ArrayList ();
				ArrayList d;
				for (int i = 0; (d = (ArrayList) dat[i]) != null; i++) {
					Dictionary<string, object> o = new Dictionary<string, object> ();
					string f;
					for (int j = 0; (f = (string) fields[j]) != null; j++) {
						o[f] = d[j];
					}
				}
				res = arr;
			} else {
				res = dat;
			}

			ctx.success (res, status, ctx);
		}

		private static void replyCompleteH (object sender, UploadValuesCompletedEventArgs status)
		{
			CharpCtx ctx = (CharpCtx) status.UserState;
			Charp charp = ctx.charp;
			Dictionary<string, object> data = charp.handleResult (status, ctx);

			if (data != null) {
				charp.replySuccess (data, status, ctx);
			}

			if (ctx.complete != null)
				ctx.complete (status, ctx);
		}

		private static string GetSHA256HexHash (SHA256 sha, string input)
		{
			byte[] data = sha.ComputeHash (Encoding.UTF8.GetBytes (input));

			StringBuilder sBuilder = new StringBuilder ();
			for (int i = 0; i < data.Length; i++) {
				sBuilder.Append (data[i].ToString ("x2"));
			}
			return sBuilder.ToString ();
		}

		private void reply (string chal, CharpCtx ctx)
		{
			Uri uri = new Uri (baseUrl + "reply");
			string hash = GetSHA256HexHash (sha, login + chal + passwd);

			NameValueCollection data = new NameValueCollection ();
			data["login"] = login;
			data["chal"] = chal;
			data["hash"] = hash;

			if (ctx.reply_handler != null) {
				ctx.reply_handler (uri, data, ctx);
				return;
			}

			ctx.wc = new WebClient ();
			ctx.wc.UploadValuesCompleted += new UploadValuesCompletedEventHandler (replyCompleteH);
			ctx.wc.UploadValuesAsync (uri, "POST", data, ctx);
		}

		private void requestSuccess (Dictionary<string, object> data, UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (ctx.asAnon) {
				replySuccess (data, status, ctx);
				return;
			}

			if (data.ContainsKey ("chal")) {
				reply ((string) data ["chal"], ctx);
				return;
			}

			handleError (ERRORS [(int) ERR.DATA_BADMSG], ctx);
		}

		private static void requestCompleteH (object sender, UploadValuesCompletedEventArgs status)
		{
			CharpCtx ctx = (CharpCtx) status.UserState;
			Charp charp = ctx.charp;
			Dictionary<string, object> data = charp.handleResult (status, ctx);
			
			if (data != null) {
				charp.requestSuccess (data, status, ctx);
			}

			if (ctx.req_complete != null)
				ctx.req_complete (status, ctx);
		}

		public void request (string resource, object[] parms = null, CharpCtx ctx = null)
		{
			if (ctx == null) {
				ctx = new CharpCtx ();
			}

			if (parms == null) {
				parms = new object[] {};
			}

			if (login == "!anonymous") {
				ctx.asAnon = true;
			}

			NameValueCollection data = new NameValueCollection ();
			data["login"] = (login == null)? "!anonymous": login;
			data["res"] = resource;
			if (ctx.asAnon) { data["anon"] = "1"; }
			data["params"] = JSON.encode (parms);

			ctx.reqData = data;
			ctx.charp = this;
			ctx.wc = new WebClient ();
			ctx.wc.UploadValuesCompleted += new UploadValuesCompletedEventHandler (requestCompleteH);
			ctx.wc.UploadValuesAsync (new Uri (baseUrl + "request"), "POST", data, ctx);
		}

		public void credentialsSet (string login, string passwd_hash) {
			this.login = login;
			this.passwd = passwd_hash;
		}
	}
}
