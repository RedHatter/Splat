/*************************************************************************
 *  PluginManager.vala
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
 *  Plugin entry point. Handles the loading of plugins, registering and calling
 *  commands, and opening Panels.
 *
 *  TODO: Floating 'quit' boxes. Status bars. after_init call. Subsignals.
 *        Load resources before init.
 */

using Gee;

extern void splat_load_plugin (string dir, string name);
extern Object splat_create_object ();
extern void splat_close_plugin ();
extern GLib.Resource splat_get_resource ();

public class libsplat.PluginManager : GLib.Object
{
	static PluginManager _instance;
	public static PluginManager instance
	{
		get
		{
			if (_instance == null)
				_instance = new PluginManager ();

			return _instance;
		}
	}

	public signal void command_called (string command, string? result, string[] args);
	public signal void panel_opened (Panel panel);

	public delegate string? Command (string[] args);
	class CommandWrap
	{
		public Command d;
		public CommandWrap (owned Command d)
		{
			this.d = (owned) d;
		}
	}

	Map<string, CommandWrap> cmds;
	Map<string, Object> plugins;

	PluginManager ()
	{
		cmds = new HashMap<string, CommandWrap> ();
		plugins = new HashMap<string, Object> ();
	}

	public void load_plugins ()
	{
		try
		{
			// Load plugins
			string file;
			var d = Dir.open(Paths.plugins);
			while ((file = d.read_name()) != null)
			{
				// Is plugin disabled or new?
				string name = file[0:file.last_index_of (".")];
				var enabled = true;
				var merge = true;

				if (Preferences.instance.has_key (@"plugins.$name"))
				{
					merge = false;
					enabled = Preferences.instance.get_boolean (@"plugins.$name.enabled");
				}

				if (!enabled)
					continue;

				// Load the .so
				splat_load_plugin (Paths.plugins + "/" + file, name);

				if (merge)
				{
					// Merge the embed settings into main settings
					var resource = splat_get_resource ();
					var parser = new Json.Parser ();
					parser.load_from_stream (resource.open_stream ("/meta.json", 0));
					Json.Object obj = parser.get_root ().get_object ();
					Preferences.instance.set_all ("", obj);
				}

				// Create instance
				plugins[name] = splat_create_object ();
				splat_close_plugin ();
			}
		} catch (Error e)
		{
			stdout.printf ("Error in PluginManager constructor: %s\n", e.message);
		}
	}

	public void open_panel (Panel panel)
	{
		panel_opened (panel);
	}

	public void register_command (string name, owned Command cmd)
	{
		cmds[name] = new CommandWrap ((owned) cmd);
	}

	public string? call_command (string name, string[] args = new string[0])
	{
		string return_val = null;

		if (cmds.has_key (name))
		{
			return_val = cmds[name].d (args);
			command_called (name, return_val, args);
		}

		return return_val;
	}

	public string call_command_str (string command)
	{
		// Find last inner most command
		var start = command.last_index_of ("[");
		if (start < 1)
		{
			// Call single command
			var index = command.index_of (" ");
			if (index < 0)
				return call_command (command);
			else
				return call_command (command[0:index], command[index+1:command.length].split (" "));
		} else
		{
			// Process last inner most command
			var end = command.index_of ("]", start);
			var inner = call_command_str (command[start+1:end]);

			// Call again with more resolved string
			return call_command_str (command[0:start] + inner + command[end+1:command.length]);
		}
	}

	public Object get_plugin (string name)
	{
		return plugins[name];
	}
}
