#if CHARP_WINDOWS
using System;

namespace monoCharp
{
	public partial class CharpGtk 
	{
		public class MSConfig : Charp.Config
		{	
			//		private GConf.Client gconf;
			private string baseUrl;
			private string baseHash;

			public MSConfig (string baseUrl)
			{
			//			gconf = null;
				this.baseUrl = baseUrl;
				if (baseUrl != null)
					baseHash = Charp.GetMD5HexHash (baseUrl);
			}

			private void Init ()
			{
		/*			if (gconf == null) {
						gconf = new GConf.Client ();
					}*/
			}
				
			public override string GetPath (string key = null)
			{
				string path = "/apps/CHARP";
				if (baseUrl != null) { path += "/" + baseHash; }
				if (key != null) { path += "/" + key; }
				return path;
			}

			public override string Get (string path) {
				Init ();
		/*		try {
					//return gconf.Get (path);
				} catch (GConf.NoSuchKeyException) {
					throw new NoSuchKeyException ();
				}*/
				return null;
			}

			public override void Set (string path, string key) {
				Init ();
				//gconf.Set (path, key);
			}

			public override void Delete (string path) {
				//Set (path, "");
			}

			public override void SuggestSync () {
				//gconf.SuggestSync ();
			}
		}
	}
}
#endif
