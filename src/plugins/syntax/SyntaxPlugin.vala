/*************************************************************************
 *  SyntaxPlugin.vala
 *  This file is part of Splat.
 *
 *  Copyright (C) 2015 Christian Johnson
 *
 *  Splat is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Splat is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Splat.  If not, see <http://www.gnu.org/licenses/>.
 ************************************************************************/

/*
	TODO: Implement language context, and import from other language.
	Fix over lapping tags (vala return types?). Guess language from file name.
	Restyle on delete. Asyc styling.
*/

using libsplat;

public class SyntaxPlugin : GLib.Object
{
	Json.Parser default_theme;
	Gee.Map<string, Json.Parser> langs;
	Gee.Map<string, Json.Parser> themes;

	Gee.Map<string, Parser> parsers;

	public void init ()
	{
		parsers = new Gee.TreeMap<string, Parser> ();
		langs = new Gee.HashMap<string, Parser> ();
		themes = new Gee.HashMap<string, Parser> ();

		try
		{
			Preferences.instance.register_menu ("list_langs", load_langs ());
			Preferences.instance.register_menu ("list_themes", load_themes ());
		} catch (Error e)
		{
			stdout.puts (@"Error: $(e.message)\n");
		}

		PluginManager.instance.command_called.connect ((command, result, args) =>
		{
			if (command == "document.new" && parsers[result] == null)
				on_new (result);
			else if (command == "files.open")
				parsers[result].set_lang (match_lang (args[0]));
		});
		PluginManager.instance.register_command ("syntax.set_theme", set_theme);
		PluginManager.instance.register_command ("syntax.set_lang", set_lang);
	}

	/*
	 *  Usage: set_theme [id] [theme]
	 *   Sets the theme of document [id].
	 */
	public string? set_theme (string[] args)
	{
		var id = args[0];
		var theme = args[1];
		if (theme == null || id == null)
			return null;

		parsers[id].set_theme (themes[theme]);

		return null;
	}

	/*
	 *  Usage: set_lang [id] [lang]
	 *   Sets the language of document [id].
	 */
	public string? set_lang (string[] args)
	{
		var id = args[0];
		var lang = args[1];
		if (lang == null || id == null)
			return null;

		parsers[id].set_lang (langs[lang]);

		return null;
	}

	public Json.Parser? match_lang (string file)
	{
		foreach (var lang in langs.values)
		{
			var types = lang.get_root ().get_object ().get_member ("fileTypes").get_array ();
			for (var i = 0; i < types.get_length (); i++)
				if (file.has_suffix (types.get_string_element (i)))
					return lang;
		}

		return null;
	}

	public Gee.ArrayList<Preferences.ItemInfo?> load_themes () throws Error
	{
	var d = Dir.open(Paths.files + "/themes");
	string file;
	var items = new Gee.ArrayList<Preferences.ItemInfo?> ();
	var default_name = Preferences.instance.get_string ("theme");
	while ((file = d.read_name()) != null)
	{
		var theme = new Json.Parser ();
		theme.load_from_data ("{}");

		var sublime = new Json.Parser ();
		sublime.load_from_file (@"$(Paths.files)/themes/$file");
		translate_theme (sublime, theme);

		string name = theme.get_root ().get_object ().get_member ("name").get_string ();
		string uuid = theme.get_root ().get_object ().get_member ("uuid").get_string ();
		themes[uuid] = theme;
		items.add (Preferences.ItemInfo ()
		{
			id = @"syntax.theme.$uuid",
			name = name,
			command = @"syntax.set_theme [document.active] $uuid"
		});

		if (name == default_name)
			default_theme = theme;
	}

	return items;
	}

	public Gee.List<Preferences.ItemInfo?> load_langs () throws Error
	{
		var d = Dir.open(Paths.files + "/langs");
		string file;
		var items = new Gee.ArrayList<Preferences.ItemInfo?> ();
		while ((file = d.read_name()) != null)
		{
			var lang = new Json.Parser ();
			lang.load_from_file (@"$(Paths.files)/langs/$file");
			string scope = lang.get_root ().get_object ().get_member ("scopeName").get_string ();
			string name = lang.get_root ().get_object ().get_member ("name").get_string ();
			langs[scope] = lang;

			items.add (Preferences.ItemInfo ()
			{
				id = @"syntax.lang.$scope",
				name = name,
				command = @"syntax.set_lang [document.active] $scope"
			});
		}

		return items;
	}

	private Parser on_new (string id)
	{
		var document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		var doc = document.get_view (id);
		var parser = new Parser (doc);
		parser.set_theme (default_theme);
		parsers[id] = parser;

		return parser;
	}


	public void translate_theme (Json.Parser file, Json.Parser theme)
	{
		var root = file.get_root ().get_object ();
		theme.get_root ().get_object ().set_member ("name", root.get_member ("name"));
		theme.get_root ().get_object ().set_member ("uuid", root.get_member ("uuid"));
		root.get_member ("settings").get_array ().foreach_element ((array, index, node) =>
		{
			var obj = node.get_object ();
			if (obj.has_member ("scope"))
			{
				var scopes = obj.get_member ("scope").get_string ().split_set (", ");
				var key_value = obj.get_member ("settings").get_object ();
				foreach (var scope in scopes)
				{
					if (scope != "")
					set_key (scope, key_value, theme);
				}
			} else
			{
				set_key ("", obj.get_member ("settings").get_object (), theme);
			}
		});
	}

	public void set_key (string key, Json.Object key_value, Json.Parser theme)
	{
		string[] keys = key.split (".");
		var obj = theme.get_root ().get_object ();
		foreach (var name in keys)
		{
			if (!obj.has_member (name))
				obj.set_object_member (name, new Json.Object ());

			obj = obj.get_member (name).get_object ();
		}

		foreach (unowned string name in key_value.get_members ())
			obj.set_member (name, key_value.get_member (name));
	}
}
