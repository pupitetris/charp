using System;
using Gtk;
using monoCharp;

public partial class MainWindow: Gtk.Window
{	
	private Charp charp;

	public MainWindow (Charp charp): base (Gtk.WindowType.Toplevel)
	{
		Build ();
		this.charp = charp;
	}
	
	protected void OnDeleteEvent (object sender, DeleteEventArgs a)
	{
		Application.Quit ();
		a.RetVal = true;
	}

	protected void testySuccess (object data, Charp.CharpCtx ctx)
	{
		Console.WriteLine ("success " + entryResource.Text);
	}

	protected void testyClick (object sender, EventArgs e)
	{
		charp.request (entryResource.Text, null, new Charp.CharpCtx () { success = testySuccess });
	}

	protected void testyFileClick (object sender, EventArgs e)
	{
		charp.request (entryResource.Text, null, new Charp.CharpCtx () { success = testySuccess, asAnon = true, fileName = "C:\\opt\\test.png" });
	}
}
