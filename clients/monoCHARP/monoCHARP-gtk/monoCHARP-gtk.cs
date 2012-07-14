using System;
using monoCharp;

namespace monoCharp
{
	public class CharpGtk : monoCharp.Charp
	{
		public CharpGtk ()
		{
		}

		public override void handleError (CharpError err, CharpCtx ctx = null)
		{
			Console.WriteLine (err.ToString ());
		}
	}
}
