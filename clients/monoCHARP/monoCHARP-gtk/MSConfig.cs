#if CHARP_WINDOWS
using System;
using System.Configuration;

namespace monoCharp
{
	public partial class CharpGtk 
	{
		public class MSConfig : Charp.Config
		{
			private static string CHARP_SECTION_NAME = "charp";
			private Configuration config;
			private string baseUrl;
			private string baseHash;

			public MSConfig (string baseUrl)
			{
				this.baseUrl = baseUrl;
				if (baseUrl != null)
					baseHash = Charp.GetMD5HexHash (baseUrl);
			}

			private KeyValueConfigurationCollection Init ()
			{
				if (config == null) {
					config = ConfigurationManager.OpenExeConfiguration (ConfigurationUserLevel.PerUserRoamingAndLocal);
					if (config.Sections [CHARP_SECTION_NAME] == null) {
						AppSettingsSection section = new AppSettingsSection ();
						section.SectionInformation.AllowExeDefinition = ConfigurationAllowExeDefinition.MachineToLocalUser;
						config.Sections.Add (CHARP_SECTION_NAME, section);
						SuggestSync ();
#if DEBUG
						Console.WriteLine (config.FilePath);
#endif
					}
				}
				return (config.GetSection (CHARP_SECTION_NAME) as AppSettingsSection).Settings;
			}
				
			public override string GetPath (string key = null)
			{
				string path = "";
				if (baseUrl != null) { path += "/" + baseHash; }
				if (key != null) { path += "/" + key; }
				return path;
			}

			public override string Get (string path) {
				var settings = Init ();
				if (settings [path] == null)
					throw new NoSuchKeyException ();
				return settings [path].Value;
			}

			public override void Set (string path, string value) {
				var settings = Init ();
				if (settings [path] == null)
					settings.Add (path, value);
				else
					settings [path].Value = value;
			}

			public override void Delete (string path) {
				var settings = Init ();
				settings.Remove (path);
			}

			public override void SuggestSync () {
				config.Save (ConfigurationSaveMode.Modified);
				ConfigurationManager.RefreshSection (CHARP_SECTION_NAME);
			}
		}
	}
}
#endif
