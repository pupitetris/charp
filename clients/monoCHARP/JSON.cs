using System;

namespace monoCHARP
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
			return fastJSON.JSON.Instance.ToJSON (obj);
		}

		static public object decode (string jsonstr)
		{
			return fastJSON.JSON.Instance.Parse (jsonstr);
		}
	}
}