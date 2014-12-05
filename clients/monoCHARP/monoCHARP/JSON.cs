using System;
using System.Text; // for Encoding.UTF8
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace monoCharp
{
	public class JSON
	{
		private JSON ()
		{
		}

		static JSON ()
		{
			// fastJSON.JSON.Instance.Parameters.UseExtensions = false;
		}
		
		static public string encode (object obj)
		{
			return JsonConvert.SerializeObject (obj);
		}

		static public JObject decode (string jsonstr)
		{
			return JObject.Parse (jsonstr);
		}

		static public JObject decode (byte[] result)
		{
			return decode (Encoding.UTF8.GetString (result));
		}
	}
}