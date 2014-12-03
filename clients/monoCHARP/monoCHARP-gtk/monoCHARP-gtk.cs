using System;
using Gtk;
using monoCharp;

namespace monoCharp
{
	public partial class CharpGtk : Charp
	{
		public class CharpGtkCtx : Charp.CharpCtx
		{
			public Gtk.Window parent;
		}

		private CharpGtk.Config conf;
		public Gtk.Window parent;

		public CharpGtk (Gtk.Window parent = null)
		{
			this.parent = parent;
			InitConf (BaseUrl);
		}

		private void InitConf (string baseUrl) {
			#if CHARP_WINDOWS
			this.conf = new CharpGtk.MSConfig (baseUrl);
			#else
			this.conf = new CharpGtk.GConfConfig (baseUrl);
			#endif
		}

		public override void BaseUrlChange (string value) {
			InitConf (value);
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
		
		public override void credentialsSave ()
		{
			conf.Set (conf.GetPath ("login"), login);
			conf.Set (conf.GetPath ("passwd"), passwd);
			conf.SuggestSync ();
		}

		public override string credentialsLoad ()
		{
			try {
				login = (string) conf.Get (conf.GetPath ("login"));
				passwd = (string) conf.Get (conf.GetPath ("passwd"));
			} catch (Charp.Config.NoSuchKeyException) {
				return null;
			}
			return login;
		}

		public override void credentialsDelete ()
		{
			conf.Delete (conf.GetPath ("login"));
			conf.Delete (conf.GetPath ("passwd"));
			conf.SuggestSync ();
		}
	}
}
