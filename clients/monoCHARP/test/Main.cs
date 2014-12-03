using System;
using Gtk;
using monoCharp;

namespace test
{
	class MainClass
	{
		public static CharpGtk charp;

		public static void Main (string[] args)
		{
			Application.Init ();

			charp = new CharpGtk ("http://www.imr.local/");
			charp.credentialsSet ("testuser", "6f1ed002ab5595859014ebf0951522d9");
			charp.credentialsSave ();

			MainWindow win = new MainWindow (charp);
			win.Show ();
			Application.Run ();
		}
	}
}
