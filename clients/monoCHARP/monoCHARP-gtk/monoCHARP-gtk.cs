using System;
using Gtk;
using monoCharp;

namespace monoCharp
{
	public class CharpGtk : Charp
	{
		public class CharpGtkCtx : Charp.CharpCtx
		{
			public Gtk.Window parent;
		}

		private GConf.Client gconf;
		public Gtk.Window parent;

		public CharpGtk (Gtk.Window parent = null)
		{
			this.parent = parent;
		}

		public override void handleError (CharpError err, CharpCtx ctx = null)
		{
			if (ctx != null && ctx.error != null && !ctx.error (err, ctx)) {
					return;
			}

			Gtk.Application.Invoke (delegate {
				CharpGtkErrorDlg dlg = new CharpGtkErrorDlg (err, ctx);
				if (ctx is CharpGtkCtx && ((CharpGtkCtx) ctx).parent != null) {
					dlg.TransientFor = ((CharpGtkCtx) ctx).parent;
				} else if (parent != null) {
					dlg.TransientFor = parent;
				}
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
			try {
				login = (string) gconf.Get (getGConfPath ("login"));
				passwd = (string) gconf.Get (getGConfPath ("passwd"));
			} catch (GConf.NoSuchKeyException) {
				return null;
			}
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
