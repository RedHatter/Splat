public class Paths : Object
{
	static string _root;
	static string root
	{
		get
		{
			if (_root == null)
			{
				char[] exe = new char[1024];
				Posix.readlink ("/proc/self/exe", exe);
				var str = (string) exe;
				_root = str[0:str.last_index_of ("/")];
			}

			return _root;
		}
	}

	static string _settings;
	public static string settings
	{
		get
		{
			if (_settings == null)
				_settings = root + "/settings.json";

				return _settings;
		}
	}

	static string _cache;
	public static string cache
	{
		get
		{
			if (_cache == null)
				_cache = root + "/cache";

			return _cache;
		}
	}

	static string _plugins;
	public static string plugins
	{
		get
		{
			if (_plugins == null)
				_plugins = root + "/plugins";

			return _plugins;
		}
	}

	public static string files
	{
		get
		{
			return root;
		}
	}
}
