using System;

#if CHARP_LINUX
namespace monoCharp.CharpGtk
{
	public partial class CharpGtk
	{
		public class GConfConfig : Charp.Config
		{
			private GConf.Client gconf;
			private string baseUrl;
			private string baseHash;

			public GConfConfig (string baseUrl)
			{
				gconf = null;
				this.baseUrl = baseUrl;
				if (baseUrl != null)
					baseHash = Charp.GetMD5HexHash (baseUrl);
			}

			private void Init ()
			{
				if (gconf == null) {
					gconf = new GConf.Client ();
				}
			}

			public string GetPath (string key = null)
			{
				string path = "/apps/CHARP";
				if (baseUrl != null) { path += "/" + baseHash; }
				if (key != null) { path += "/" + key; }
				return path;
			}

			public string Get (string path) {
				Init ();
				try {
					return gconf.Get (path);
				} catch (GConf.NoSuchKeyException) {
					throw new NoSuchKeyException ();
				}
				return null;
			}

			public void Set (string path, string value) {
				Init ();
				gconf.Set (path, value);
			}

			public void Delete (string path) {
				Set (path, "");
			}

			public void SuggestSync () {
				gconf.SuggestSync ();
			}
		}
	}
}
#endif
