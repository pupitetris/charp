using System;
using Gtk;
using monoCHARP;

namespace test
{
	class MainClass
	{
		public static void Main (string[] args)
		{
			var charp = new CHARP ();
			Application.Init ();
			MainWindow win = new MainWindow ();
			win.Show ();
			Application.Run ();
		}
	}
}
