using System;
using Gtk;
using monoCharp;
using System.Net;

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

	protected void testySuccess (object data, UploadValuesCompletedEventArgs status, Charp.CharpCtx ctx)
	{
		Console.WriteLine ("success " + entryResource.Text);
	}

	protected void testyClick (object sender, EventArgs e)
	{
		charp.request (entryResource.Text, null, new Charp.CharpCtx () { success = testySuccess });
	}
}
