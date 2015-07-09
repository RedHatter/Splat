/*************************************************************************
 *  Preferences.vala
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
 *  Singleton that stores and sets application settings. Uses the Json format.
 */
public class libsplat.Preferences : GLib.Object
{
	static Preferences _instance;
	public static Preferences instance
	{
		get
		{
			if (_instance == null)
				_instance = new Preferences ();

			return _instance;
		}
	}

	Json.Parser model;

	public struct ItemInfo
	{
		public string name;
		public string id;
		public string command;
		public string accel;
	}

	Gee.Map<string, Gee.List<ItemInfo?>> menus;

	construct
	{
		try
		{
			// Load settings file
			model = new Json.Parser ();
			if (File.new_for_path ("./settings.json").query_exists ())
				model.load_from_file ("./settings.json");
			else
				model.load_from_data ("{ \"plugins\": {} }");
		} catch (Error e)
		{
			stdout.printf ("Error in Preferences constructor: %s\n", e.message);
		}

		menus = new Gee.HashMap<string, Gee.List<ItemInfo?>> ();
	}

	// ~Preferences ()
	// {
	// 	write ();
	// }

	public bool has_key (string key)
	{
		return get_node (key) != null;
	}

	public string? get_string (string key)
	{
		var node = get_node (key);
		if (node != null)
			return node.get_string ();
		else
			return null;
	}

	public bool? get_boolean (string key)
	{
		var node = get_node (key);
		if (node != null)
			return node.get_boolean ();
		else
			return null;
	}

	public double? get_double (string key)
	{
		var node = get_node (key);
		if (node != null)
			return node.get_double ();
		else
			return null;
	}

	public int? get_int (string key)
	{
		var node = get_node (key);
		if (node != null)
			return (int) node.get_int ();
		else
			return null;
	}

	public string[]? get_array (string key)
	{
		var node = get_node (key);
		if (node == null)
			return null;

		var array_node = get_node (key).get_array ();
		var array = new string [array_node.get_length ()];
		array_node.foreach_element ((a, i, node) => array[i] = node.get_string ());
		return array;
	}

	private Json.Node? get_node (string key)
	{
		string[] keys = key.split (".");
		var node = model.get_root ();
		foreach (var name in keys)
		{
			if (node == null)
				return null;

			node = node.get_object ().get_member (name);
		}

		return node;
	}

	public void set_string (string key, string value)
	{
		var node = new Json.Node (Json.NodeType.VALUE);
		node.set_string (value);
		set_node (key, node);
	}

	public void set_boolean (string key, bool value)
	{
		var node = new Json.Node (Json.NodeType.VALUE);
		node.set_boolean (value);
		set_node (key, node);
	}

	public void set_int (string key, int value)
	{
		var node = new Json.Node (Json.NodeType.VALUE);
		node.set_int (value);
		set_node (key, node);
	}

	public void set_double (string key, double value)
	{
		var node = new Json.Node (Json.NodeType.VALUE);
		node.set_double (value);
		set_node (key, node);
	}

	public void set_array (string key, string[] value)
	{
		var array = new Json.Array.sized (value.length);
		foreach (var str in value)
			array.add_string_element (str);

		var node = new Json.Node (Json.NodeType.VALUE);
		node.set_array (array);
		set_node (key, node);
	}

	private void set_node (string key, Json.Node node)
	{
		string[] keys = key.split (".");
		var obj = model.get_root ().get_object ();

		for (int i = 0; i < keys.length-1; i++)
		{
			if (obj.has_member (keys[i]))
				obj = obj.get_object_member (keys[i]);
			else
			{
				var temp = new Json.Object ();
				obj.set_object_member (keys[i], temp);
				obj = temp;
			}
		}

		obj.set_member (keys[keys.length-1], node);
	}

	public void set_all (string key, Json.Object new_obj)
	{
		string[] keys = key.split (".");
		var obj = model.get_root ().get_object ();

		foreach (var name in keys)
		{
			if (obj.has_member (name))
				obj = obj.get_object_member (name);
			else
			{
				var temp = new Json.Object ();
				obj.set_object_member (name, temp);
				obj = temp;
			}
		}

		merge (new_obj, obj);
	}

	public void delete_key (string key)
	{
		var node = get_node (key);
		if (node == null)
			return;

		node.get_parent ().get_object ()
			.remove_member (key[key.last_index_of ("."):key.length]);
	}

	// TODO: Merge arrays.
	private void merge (Json.Object new_obj, Json.Object obj)
	{
		foreach (unowned string name in new_obj.get_members ())
		{
			var node = new_obj.get_member (name);
			if (obj.has_member (name) && node.get_node_type () == Json.NodeType.OBJECT)
				merge (node.get_object (), obj.get_member (name).get_object ());
			else
				obj.set_member (name, node);
		}
	}

	public void write ()
	{
		try
		{
			stdout.puts ("updating json.\n");
			// Update settings file
			Json.Generator generator = new Json.Generator ();
			generator.set_root (model.get_root ());
			generator.set_pretty (true);
			generator.to_file ("./settings.json");
		} catch (Error e)
		{
			stdout.printf ("Error in Preferences.write: %s\n", e.message);
		}
	}


	public void register_menu (string name, Gee.List<ItemInfo?> menu)
	{
		menus[name] = menu;
	}

	public MenuModel get_menu (Gtk.Application group)
	{
		var bar = new Menu ();
		var root = get_node ("menu").get_object ();
		foreach (string name in root.get_members ())
			bar.append_submenu (name, build_menu (root.get_member (name).get_object (), group));

		return bar;
	}

	private Menu build_menu (Json.Object obj, Gtk.Application group)
	{
		var menu = new Menu ();

		foreach (var name in obj.get_members ())
		{
			if (name == "menu_functions")
			{
				obj.get_member ("menu_functions").get_array ().foreach_element ((array, i, node) =>
				{
					foreach (var info in menus[node.get_string ()])
					{
						var action = new SimpleAction (info.id, null);
						action.activate.connect (() => PluginManager.instance.call_command_str (info.command));
						action.set_enabled (true);
						group.add_action (action);
						if (info.accel != null)
							group.add_accelerator (info.accel, "app."+info.id, null);
							
						menu.append (info.name, "app."+info.id);
					}
				});
				continue;
			}

			var item_obj = obj.get_member (name).get_object ();
			if (item_obj.has_member ("command"))
			{
				var command = item_obj.get_member ("command").get_string ();
				var id = item_obj.get_member ("id").get_string ();
				var accel = item_obj.get_member ("accel");
				var action = new SimpleAction (id, null);
				action.activate.connect (() => PluginManager.instance.call_command_str (command));
				action.set_enabled (true);
				group.add_action (action);
				if (accel != null)
					group.add_accelerator (accel.get_string (), "app."+id, null);
					
				menu.append (name, "app."+id);
			} else
				menu.append_submenu (name, build_menu (item_obj, group));
		}

		return menu;
	}
}
