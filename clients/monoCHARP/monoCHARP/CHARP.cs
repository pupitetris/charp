using System;
using System.IO; // for Stream
using System.Net; // for WebClient
using System.Text; // for Encoding.UTF8
using System.Collections; // for ArrayList
using System.Collections.Generic; // for Dictionary
using System.Collections.Specialized; // for NameValueCollection and StringDictionary
using System.Security.Cryptography; // for SHA256Managed
using Mono.Unix; // for Catalog
using Newtonsoft.Json.Linq;

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

			public string ToString (CharpCtx ctx = null)
			{
				StringBuilder b = new StringBuilder ();

				b.Append (((int)sev < 3) ? Catalog.GetString ("Error") : Catalog.GetString ("Warning"));
				b.AppendFormat (Catalog.GetString (" {0}: \n{1}\n"), key, desc);
				if (ctx != null) {
					b.AppendFormat (Catalog.GetString ("{0}: "), ctx.reqData ["res"]);
				}
				if (statestr != null) {
					b.Append (statestr);
				}
				if (state != "") {
					b.AppendFormat (Catalog.GetString (" ({0})\n"), state);
				}
				b.AppendFormat (Catalog.GetString ("{0}\n"), msg);
				b.AppendFormat (Catalog.GetString ("{0}\n"), ERR_SEV_MSG [(int)sev]);

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

		public delegate void SuccessDelegate (object data, UploadValuesCompletedEventArgs status, CharpCtx ctx);
		public delegate void CompleteDelegate (UploadValuesCompletedEventArgs status, CharpCtx ctx);
		public delegate bool ErrorDelegate (CharpError err, CharpCtx ctx);
		public delegate void ReplyHandlerDelegate (Uri base_uri, NameValueCollection parms, CharpCtx ctx);

		public class CharpCtx {
			// Set by you
			public SuccessDelegate success; // Called when the operation is successful.
			public ErrorDelegate error;  // Called when there's an error or exception during the request.
			public CompleteDelegate req_complete; // Called when the challenge request (1st HTTP roundtrip) is completed.
			public CompleteDelegate complete; // Called when the operation is finished, regardless of success.
			public ReplyHandlerDelegate reply_handler; // You get the URI and deal with the 2nd HTTP roundtrip yourself.
			public CompleteDelegate success_handler; // Handle the processing of the reply, instead of using the 
			                                         // default JSON parser (good for RP's returning file data).
			public bool asAnon;          // avoid a full HTTP roundtrip by using a non-authenticated remote procedure.
			public bool asArray;         // saves time for large datasets by returning the original array of arrays.
			public bool useCache;        // cache the reply?
			public bool cacheRefresh;    // force the cache to re-get data from server and store again.
			public bool cacheIsPrivate;  // privately store data in the object, not to be shared across CHARP objects.
			public string fileName;      // Optional path of a file to be sent with the reply.
			public string cacheArea;     // cache area to use. Areas can be deleted completly using cacheDeleteArea.
			public object obj;           // your stuff here.

			// Set by CHARP
			public NameValueCollection reqData;
			public Charp charp;
			public WebClient wc;

			public CharpCtx () {
				asAnon = false;
				asArray = false;
				useCache = false;
				cacheRefresh = false;
				cacheIsPrivate = false;
				cacheArea = "default";
			}
		}

		static public string BASE_URL = null;
		static private string[] ERR_SEV_MSG = null;
		static private CharpError[] ERRORS = null;
		static private SHA256Managed sha;
		static private Dictionary<string, object> commonCache;

		protected string baseUrl;
		public string BaseUrl {
			get {
				return baseUrl;
			}
			set {
				BaseUrlChange (value);
				baseUrl = value;
			}
		}
		protected string login;
		protected string passwd;
		private Dictionary<string, object> privateCache;

		static Charp ()
		{
			sha = new SHA256Managed ();
			commonCache = new Dictionary<string, object> ();

			Catalog.Init ("monoCharp", "./locale");

			if (ERR_SEV_MSG == null) { // This to avoid warning.
				ERR_SEV_MSG = new string[] {
					null,
					Catalog.GetString ("This is an internal system error. Please take note of the provided " +
					                   "information in this message and call support so a solution can be worked on."),
					Catalog.GetString ("You are trying to access unauthorized data. If you require adequate access, " +
					                   "call support."),
					Catalog.GetString ("This is a temporary error, please try again immediately or in a few minutes. " +
					                   "If the error persists, call support."),
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
						desc = Catalog.GetString ("Data obtained from the web server are malformed."), msg = null },
					new CharpError { key = "AJAX:UNK", code = -4, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.AJAX,
						desc = Catalog.GetString ("An unknown error type has occurred."), msg = null },
					new CharpError { key = "HTTP:CANCEL", code = -5, sev = ERR_SEV.RETRY, lvl = ERR_LEVEL.HTTP,
						desc = Catalog.GetString ("The connection with the web service was cancelled."), 
						msg = Catalog.GetString ("A web service operation was cancelled. Please verify that your " + 
						                         "network is in working order.") },
					new CharpError { key = "DATA:BADMSG", code = -6, sev = ERR_SEV.INTERNAL, lvl = ERR_LEVEL.DATA,
						desc = Catalog.GetString ("The JSON web service response is invalid."), msg = null }
				};
			}
		}

		static public string getErrSevMsg (ERR_SEV sev) {
			return ERR_SEV_MSG[(int) sev];
		}

		public Charp (string base_url = null)
		{
			init (base_url);
		}

		public Charp (string login, string passwdHash, string base_url = null)
		{
			init (base_url);
			credentialsSet (login, passwdHash);
		}

		private void init (string base_url)
		{
			baseUrl = (base_url == null)? BASE_URL : base_url;
			privateCache = new Dictionary<string, object> ();
		}

		public abstract void handleError (CharpError err, CharpCtx ctx = null);

		public void handleError (JToken err, CharpCtx ctx = null)
		{
			CharpError cerr = new CharpError {
				code = (int) err["code"],
				sev = (ERR_SEV) ((int) err["sev"]),
				desc = (string) err["desc"],
				msg = (string) err["msg"],
				lvl = (ERR_LEVEL) ((int) err["level"]),
				key = (string) err["key"],
				state = err["state"] != null? (string) err["state"]: "",
				statestr = (string) err["statestr"]
			};

			handleError (cerr, ctx);
		}

		public bool resultHandleErrors (UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (status.Cancelled) {
				handleError (ERRORS [(int) ERR.HTTP_CANCEL], ctx);
				return false;
			} 
			
			if (status.Error != null) {
				CharpError err = ERRORS [(int) ERR.HTTP_SRVERR];
				err.msg = String.Format (Catalog.GetString ("HTTP WebClient error: {0}"), status.Error.ToString ());
				handleError (err, ctx);
				return false;
			}
			
			if (status.Result == null || status.Result.Length == 0) {
				handleError (ERRORS [(int) ERR.HTTP_CONNECT], ctx);
				return false;
			}

			return true;
		}

		private JObject handleResult (UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (!resultHandleErrors (status, ctx))
				return null;

			if (ctx.success_handler != null) {
				if (ctx.useCache)
					cacheSet (ctx, status);
				ctx.success_handler (status, ctx);
				return null;
			}

			JObject data;
			try {
				data = JSON.decode (status.Result);
			} catch (Exception e) {
				CharpError err = ERRORS [(int) ERR.AJAX_JSON];
				err.msg = String.Format (Catalog.GetString ("Error: {0}, Data: {1}"), 
				                         e.Message, Encoding.UTF8.GetString (status.Result));
				handleError (err, ctx);
				return null;
			}
			
			if (data["error"] != null) {
				handleError (data ["error"], ctx);
				return null;
			}

			return data;
		}

		public abstract class Config {
			public abstract void SetApp (string appName);
			public abstract string GetPath (string key = null);
			public abstract string Get (string path);
			public abstract void Set (string path, string value);
			public abstract void Delete (string path);
			public abstract void SuggestSync ();

			public void Set (string path, int value) {
				Set (path, value.ToString ());
			}

			public int GetInt (string path) {
				return Int32.Parse (Get (path));
			}

			public class NoSuchKeyException : Exception {};
		}

		private class PathBuilder
		{
			private StringBuilder sb;

			public PathBuilder ()
			{
				sb = new StringBuilder ();
			}
			
			public PathBuilder Append (string str) {
				sb.Append (str);
				return this;
			}
			
			public PathBuilder AppendNode (string str) {
				sb.Append (str).Append ('»');
				return this;
			}

			public override string ToString () {
				return sb.ToString ();
			}
		}
		
		private string cacheCtxToPath (CharpCtx ctx) {
			PathBuilder path = new PathBuilder ();
			
			if (ctx.cacheIsPrivate)
				path.Append ("u:").AppendNode (ctx.reqData["login"]);
			else
				path.AppendNode ("public");
			
			path.AppendNode (ctx.reqData["res"])
				.AppendNode (ctx.reqData["params"]);
			
			return path.ToString ();
		}

		private object cacheGet (CharpCtx ctx)
		{
			Dictionary<string, object> cache = (ctx.cacheIsPrivate)? privateCache: commonCache;

			if (!cache.ContainsKey (ctx.cacheArea))
				return null;

			Dictionary<string, object> area = (Dictionary<string, object>) cache[ctx.cacheArea];
			string path = cacheCtxToPath (ctx);
			if (!area.ContainsKey (path))
				return null;
			return area[path];
		}

		private void cacheSet (CharpCtx ctx, object res)
		{
			Dictionary<string, object> cache = (ctx.cacheIsPrivate)? privateCache: commonCache;
			
			if (!cache.ContainsKey (ctx.cacheArea))
				cache[ctx.cacheArea] = new Dictionary<string, object> ();
			Dictionary<string, object> area = (Dictionary<string, object>) cache[ctx.cacheArea];
			string path = cacheCtxToPath (ctx);
			area[path] = res;
		}

		public void cacheDeleteArea (string area, bool isPrivate)
		{
			Dictionary<string, object> cache = (isPrivate)? privateCache: commonCache;
			if (cache.ContainsKey (area))
				cache[area] = null;
		}

		private void replySuccess (JObject data, UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (data["fields"] == null || data["data"] == null) {
				handleError (ERRORS [(int) ERR.DATA_BADMSG], ctx);
			}

			object res;
			JArray fields = (JArray) data["fields"];
			JArray dat = (JArray) data["data"];

			if (fields.Count == 1 && (string) fields[0] == "rp_" + ctx.reqData["res"]) {
				res = dat[0][0];
			} else if (!ctx.asArray) {
				JArray arr = new JArray ();
				JArray row;
				for (int i = 0; i < dat.Count; i++) {
					row = (JArray) dat[i];

					JObject so = new JObject ();
					string fieldName;
					for (int j = 0; j < fields.Count; j++) {
						fieldName = (string) fields[j];
						so[fieldName] = row[j];
					}

					arr.Add (so);
				}
				res = arr;
			} else {
				res = dat;
			}

			if (ctx.useCache)
				cacheSet (ctx, res);

			if (ctx.success != null)
				ctx.success (res, status, ctx);
		}

		private static void replyCompleteH (object sender, UploadValuesCompletedEventArgs status)
		{
			CharpCtx ctx = (CharpCtx) status.UserState;
			Charp charp = ctx.charp;
			JObject data = charp.handleResult (status, ctx);

			if (data != null) {
				charp.replySuccess (data, status, ctx);
			}

			if (ctx.complete != null)
				ctx.complete (status, ctx);
		}

		public static string GetMD5HexHash (string input)
		{
			return GetHexHash (new MD5CryptoServiceProvider (), input);
		}

		private static string GetHexHash (HashAlgorithm hash, string input)
		{
			byte[] data = hash.ComputeHash (Encoding.UTF8.GetBytes (input));

			StringBuilder sBuilder = new StringBuilder ();
			for (int i = 0; i < data.Length; i++) {
				sBuilder.Append (data[i].ToString ("x2"));
			}
			return sBuilder.ToString ();
		}

		private void reply (string chal, CharpCtx ctx)
		{
			Uri uri = new Uri (baseUrl + "reply");
			string hash = GetHexHash (sha, login + chal + passwd);

			NameValueCollection data = new NameValueCollection () {
				{ "login", login },
				{ "chal", chal },
				{ "hash", hash }
			};

			if (ctx.reply_handler != null) {
				ctx.reply_handler (uri, data, ctx);
				return;
			}

			if (ctx.fileName != null) {
				HttpUploadFileAsync (uri, data, ctx);
				return;
			}

			ctx.wc = new WebClient ();
			ctx.wc.UploadValuesCompleted += new UploadValuesCompletedEventHandler (replyCompleteH);
			ctx.wc.UploadValuesAsync (uri, "POST", data, ctx);
		}

		private static void HttpUploadFileResponseH (IAsyncResult res) {
			Dictionary<string,object> state = (Dictionary<string,object>) res.AsyncState;

			HttpWebRequest wr = (HttpWebRequest) state["wr"];
			CharpCtx ctx = (CharpCtx) state["ctx"];

			WebResponse wresp = null;

			try {
				wresp = wr.EndGetResponse(res);
				Stream stream2 = wresp.GetResponseStream();
				StreamReader reader2 = new StreamReader(stream2);
				// JSON
			} catch(Exception ex) {
				// TODO: Handle error
				if(wresp != null) {
					wresp.Close();
					wresp = null;
				}
			}
		}

		private static void HttpUploadFileRequestStreamH (IAsyncResult res) {
			Dictionary<string,object> state = (Dictionary<string,object>) res.AsyncState;

			HttpWebRequest wr = (HttpWebRequest) state["wr"];
			string boundary = (string) state["boundary"];
			NameValueCollection data = (NameValueCollection) state["data"];
			CharpCtx ctx = (CharpCtx) state["ctx"];

			byte[] boundarybytes = System.Text.Encoding.ASCII.GetBytes("\r\n--" + boundary + "\r\n");

			Stream rs = wr.EndGetRequestStream (res);

			string formdataTemplate = "Content-Disposition: form-data; name=\"{0}\"\r\n\r\n{1}";
			foreach (string key in data.Keys)
			{
				rs.Write(boundarybytes, 0, boundarybytes.Length);
				string formitem = string.Format(formdataTemplate, key, data[key]);
				byte[] formitembytes = System.Text.Encoding.UTF8.GetBytes(formitem);
				rs.Write(formitembytes, 0, formitembytes.Length);
			}
			rs.Write(boundarybytes, 0, boundarybytes.Length);

			string header = "Content-Disposition: form-data; name=\"file\"; filename=\"fname\"\r\nContent-Type: application/octet-stream\r\n\r\n";
			byte[] headerbytes = System.Text.Encoding.UTF8.GetBytes(header);
			rs.Write(headerbytes, 0, headerbytes.Length);

			FileStream fileStream = new FileStream(ctx.fileName, FileMode.Open, FileAccess.Read);
			byte[] buffer = new byte[4096];
			int bytesRead = 0;
			while ((bytesRead = fileStream.Read(buffer, 0, buffer.Length)) != 0) {
				rs.Write(buffer, 0, bytesRead);
			}
			fileStream.Close();

			byte[] trailer = System.Text.Encoding.ASCII.GetBytes("\r\n--" + boundary + "--\r\n");
			rs.Write(trailer, 0, trailer.Length);
			rs.Close();

			Dictionary<string,object> state2 = new Dictionary<string,object>() {
				{"ctx", ctx},
				{"wr", wr}
			};

			wr.BeginGetResponse (new AsyncCallback (HttpUploadFileResponseH), state2);
		}

		private void HttpUploadFileAsync (Uri uri, NameValueCollection data, CharpCtx ctx) {
			string boundary = "---------------------------" + DateTime.Now.Ticks.ToString("x");

			HttpWebRequest wr = (HttpWebRequest)WebRequest.Create (uri);
			wr.ContentType = "multipart/form-data; boundary=" + boundary;
			wr.Method = "POST";
			wr.KeepAlive = true;
			wr.Credentials = System.Net.CredentialCache.DefaultCredentials;

			Dictionary<string,object> state = new Dictionary<string,object>() {
				{"data", data},
				{"ctx", ctx},
				{"boundary", boundary},
				{"wr", wr},
			};

			wr.BeginGetRequestStream (new AsyncCallback (HttpUploadFileRequestStreamH), state);
		}

		private void requestSuccess (JObject data, UploadValuesCompletedEventArgs status, CharpCtx ctx)
		{
			if (ctx.asAnon) {
				replySuccess (data, status, ctx);
				return;
			}

			if (data["chal"] != null) {
				reply ((string) data ["chal"], ctx);
				return;
			}

			handleError (ERRORS [(int) ERR.DATA_BADMSG], ctx);
		}

		private static void requestCompleteH (object sender, UploadValuesCompletedEventArgs status)
		{
			CharpCtx ctx = (CharpCtx) status.UserState;
			Charp charp = ctx.charp;
			JObject data = charp.handleResult (status, ctx);
			
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

			NameValueCollection data = new NameValueCollection () {
				{ "login", (login == null)? "!anonymous" : login },
				{ "res", resource },
				{ "params", JSON.encode (parms) }
			};
			if (ctx.asAnon)
				data["anon"] = "1";

			ctx.reqData = data;

			if (ctx.useCache && !ctx.cacheRefresh) {
				object res = cacheGet (ctx);
				if (res != null) {
					if (ctx.req_complete != null)
						ctx.req_complete (null, ctx);
					if (ctx.success_handler != null) {
						ctx.success_handler ((UploadValuesCompletedEventArgs) res, ctx);
					} else {
						if (ctx.success != null)
							ctx.success (res, null, ctx);
					}
					if (ctx.complete != null)
						ctx.complete (null, ctx);
					return;
				}
			}

			ctx.charp = this;
			ctx.wc = new WebClient ();
			ctx.wc.UploadValuesCompleted += new UploadValuesCompletedEventHandler (requestCompleteH);
			ctx.wc.UploadValuesAsync (new Uri (baseUrl + "request"), "POST", data, ctx);
		}

		public void credentialsSet (string login, string passwd_hash) {
			this.login = login;
			this.passwd = passwd_hash;
		}

		public abstract void credentialsSave ();
		public abstract string credentialsLoad ();
		public abstract void credentialsDelete ();

		public abstract void BaseUrlChange (string value);
	}
}
