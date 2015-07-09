/*************************************************************************
 *  Files.vala
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
 *  Saving and loading files.
 *
 *	TODO: Recently open files. Open dialog in active document directory.
 */

using libsplat;

public class FilesPlugin : GLib.Object
{
	Gee.Map<string,File> files;

	// void save_state ()
	// {
	// 	var array = new string[files.size];
	// 	foreach (var entry in files.entries)
	// 		array[i] = @"$(entry.key):$(entry.value.get_parse_name ())";

	// 		Preferences.set_array ("catche.files", array);
	// }

	// void load_state ()
	// {
	// 	var array = Preferences.get_array ("catche.files");
	// 	for (var item in array)
	// 	{
	// 		var i = item.index_of (":");
	// 		files[item[0:i]] = File.parse_name (item[i:item.length]);
	// 	}
	// }

	public void init ()
	{
		files = new Gee.HashMap<string,File> ();
		PluginManager.instance.register_command ("files.open", open);
		PluginManager.instance.register_command ("files.save", save);
		PluginManager.instance.register_command ("files.dialog", dialog);

		// load_state ()
	}

	/*
	 *  Usage: save [id] [path=?]
	 *   Writes the contents of the document signified by [id] to the file at [path].
	 *   If [path] is unset will attempt to retrieve where it was loaded from.
	 */
	public string? save (string[] args)
	{
		try
		{
			string id = args[0];
			if (id == null)
				return null;

			File file = args[1] == null ? files[id] : File.new_for_commandline_arg (args[1]);
			if (file == null)
				file = File.new_for_commandline_arg (PluginManager.instance.call_command ("files.dialog", new string[]{"false"}));

			string contents = PluginManager.instance.call_command ("document.contents", new string[]{id});
			FileOutputStream os = file.replace (null, false, FileCreateFlags.NONE);
			DataOutputStream dos = new DataOutputStream (os);
			dos.put_string (contents);
		} catch (Error e)
		{
			stdout.printf ("Error: %s\n", e.message);
		}

		return null;
	}

	/*
	 *  Usage: open [path]
	 *   Opens a new document at [path].
	 */
	public string? open (string[] args)
	{
		var file_name = args[0];
		if (file_name == null)
			return null;

		try
		{
			char[] contents;
			var file = File.new_for_commandline_arg (file_name);
			file.load_contents (null, out contents, null);
			string id = PluginManager.instance.call_command ("document.new", new string[]{file.get_basename ()});
			PluginManager.instance.call_command ("document.insert", new string[]{id, (string) contents});
			files[id] = file;
			return id;
		} catch (Error e) {
			stdout.printf ("Error: %s\n", e.message);
		}

		// save_state ();

		return null;
	}

	/*
	 *  Usage: dialog [isOpen=true]
	 *   Returns the path to the file the user picked.
	 */
	public string? dialog (string[] args)
	{
		var is_open = args[0] == "false" ? false : true;
		Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
			is_open ? "Open file" : "Save file", null, Gtk.FileChooserAction.SAVE,
			"_Cancel", Gtk.ResponseType.CANCEL,
			is_open ? "_Open" : "_Save", Gtk.ResponseType.ACCEPT);

		string return_val = null;
		if (chooser.run () == Gtk.ResponseType.ACCEPT)
			return_val = chooser.get_uris ().nth_data (0);

		chooser.close ();

		return return_val;
	}
}