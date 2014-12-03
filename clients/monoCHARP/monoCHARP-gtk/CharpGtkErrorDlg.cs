using System;
using monoCharp;
using System.Text; // for StringBuilder
using Mono.Unix; // for Catalog
using Gtk;

namespace monoCharp
{
	public partial class CharpGtkErrorDlg : Gtk.Dialog
	{
		public CharpGtkErrorDlg (Charp.CharpError err, Charp.CharpCtx ctx = null)
		{
			Build ();

			string titlestr = (((int)err.sev < 3) ? Catalog.GetString ("Error") : Catalog.GetString ("Warning")) +
				String.Format (Catalog.GetString (" {0}({1})"), err.key, err.code);
			Title = titlestr;
			labelTitle.Text = titlestr;

			if ((int) err.sev >= 3) {
				imageIcon.Pixbuf = Gdk.Pixbuf.LoadFromResource ("monoCharp.warning.png");
				Icon = Gdk.Pixbuf.LoadFromResource ("monoCharp.warning.png");
			}

			labelDesc.Text = err.desc;

			StringBuilder b = new StringBuilder (Catalog.GetString ("<i><tt><small>"));
			if (ctx != null) {
				b.AppendFormat (Catalog.GetString ("{0}: "),  GLib.Markup.EscapeText (ctx.reqData ["res"]));
			}
			if (err.statestr != null) {
				b.Append (GLib.Markup.EscapeText (err.statestr));
			}
			if (err.state != "") {
				b.AppendFormat (Catalog.GetString (" ({0})"), GLib.Markup.EscapeText (err.state));
			}
			b.Append ("\n");
			b.AppendFormat (Catalog.GetString ("{0}</small></tt></i>"), GLib.Markup.EscapeText (err.msg));
			labelMsg.UseMarkup = true;
			labelMsg.Markup = b.ToString ();

			labelSev.Text = Charp.getErrSevMsg (err.sev);
		}

		protected void OnButtonCloseClicked (object sender, EventArgs e)
		{
			this.Destroy ();
		}
	}
}
