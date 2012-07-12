using System;
using Mono.Unix;

namespace monoCHARP
{
	public class CHARP
	{
		static CHARP ()
		{
			Catalog.Init ("monoCHARP", "./locale");

			if (ERROR_SEV_MSG == null) { // This to avoid warning.
				ERROR_SEV_MSG = new string[] {
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
					new charpError { key = "HTTP:CONNECT", code = -1, sev = ERROR_SEV.RETRY, lvl = ERROR_LEVEL.HTTP,
						desc = Catalog.GetString ("Impossible to contact the web service."), msg = Catalog.GetString ("Verify that your network connection works and try again.") },
					new charpError { key = "HTTP:SRVERR", code = -2, sev = ERROR_SEV.INTERNAL, lvl = ERROR_LEVEL.HTTP,
						desc = Catalog.GetString ("The web server replied with an error."), msg = null },
					new charpError { key = "AJAX:JSON", code = -3, sev = ERROR_SEV.INTERNAL, lvl = ERROR_LEVEL.AJAX,
						desc = Catalog.GetString ("Data obtained from the web server are malformed."), msg = null },
					new charpError { key = "AJAX:UNK", code = -4, sev = ERROR_SEV.INTERNAL, lvl = ERROR_LEVEL.AJAX,
						desc = Catalog.GetString ("An unknown error type has occurred."), msg = null }
				};
			}
		}
		
		public CHARP ()
		{
			BASE_URL = null;
		}
		
		public string BASE_URL { get; set; }
		
		public enum ERROR_SEV {
			INTERNAL = 1,
			PERM,
			RETRY,
			USER,
			EXIT
		};
		
		static private string[] ERROR_SEV_MSG = null;
		
		public enum ERROR_LEVEL {
			DATA = 1,
			SQL,
			DBI,
			CGI,
			HTTP,
			AJAX
		}
		
		private struct charpError {
			public int code;
			public ERROR_SEV sev;
			public string desc;
			public string msg;
			public ERROR_LEVEL lvl;
			public string key;
		}
		
		static private charpError[] ERRORS = null;
	}
}

