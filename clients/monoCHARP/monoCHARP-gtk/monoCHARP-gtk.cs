using System;
using GtkSharp;
using monoCharp;

namespace monoCharp
{
	public class CharpGtk : monoCharp.Charp
	{
		private GConf.Client gconf = null;

		public CharpGtk ()
		{
		}

		public override void handleError (CharpError err, CharpCtx ctx = null)
		{
			Gtk.Application.Invoke (delegate {
				CharpGtkErrorDlg dlg = new CharpGtkErrorDlg (err, ctx);
				dlg.Run ();
			});
		}
		
		private void gConfChanged (object sender, GConf.NotifyEventArgs args)
		{
			credentialsLoad ();
		}

		private string getGConfPath (string key = null)
		{
			string path = "/apps/CHARP";
			if (baseUrl != null) { path += "/" + GetMD5HexHash (baseUrl); }
			if (key != null) { path += "/" + key; }
			return path;
		}

		private void gConfInit ()
		{
			if (gconf == null) {
				gconf = new GConf.Client ();
				gconf.AddNotify (getGConfPath (), gConfChanged);
			}
		}
		
		public override void credentialsSave ()
		{
			gConfInit ();
			gconf.Set (getGConfPath ("login"), login);
			gconf.Set (getGConfPath ("passwd"), passwd);
			gconf.SuggestSync ();
		}

		public override string credentialsLoad ()
		{
			gConfInit ();
			login = (string) gconf.Get (getGConfPath ("login"));
			passwd = (string) gconf.Get (getGConfPath ("passwd"));
			return login;
		}

		public override void credentialsDelete ()
		{
			gConfInit ();
			gconf.Set (getGConfPath ("login"), "");
			gconf.Set (getGConfPath ("passwd"), "");
			gconf.SuggestSync ();
		}
	}
}
