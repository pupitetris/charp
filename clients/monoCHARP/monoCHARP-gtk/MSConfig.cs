#if CHARP_WINDOWS

using System;
using System.Configuration;

namespace monoCharp
{
	public partial class CharpGtk 
	{
		public class MSConfig : Charp.Config
		{
			private static string CHARP_APP_NAME = "charp";
			private Configuration config;
			private string appName;
			private string baseUrl;
			private string baseHash;

			public MSConfig (string baseUrl)
			{
				this.baseUrl = baseUrl;
				if (baseUrl != null)
					baseHash = Charp.GetMD5HexHash (baseUrl);

				appName = CHARP_APP_NAME;
			}

			private void ChangeSection (string name)
			{
				SuggestSync ();
				if (config.Sections [name] == null) {
					AppSettingsSection section = new AppSettingsSection ();
					section.SectionInformation.AllowExeDefinition = ConfigurationAllowExeDefinition.MachineToLocalUser;
					config.Sections.Add (name, section);
					SuggestSync ();
#if DEBUG
					Console.WriteLine (config.FilePath);
#endif
				}
			}

			private KeyValueConfigurationCollection Init ()
			{
				if (config == null) {
					config = ConfigurationManager.OpenExeConfiguration (ConfigurationUserLevel.PerUserRoamingAndLocal);
					ChangeSection (appName);
				}
				return (config.GetSection (appName) as AppSettingsSection).Settings;
			}

			public override void SetApp (string app_name)
			{
				appName = app_name;
				Init ();
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
				ConfigurationManager.RefreshSection (appName);
			}
		}
	}
}

#endif
