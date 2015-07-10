/*************************************************************************
 *  DocumentPanal.vala
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

class DocumentPanel : libsplat.Panel, Gtk.ScrolledWindow
{
	// Store instances accessible by id and index
	static Gee.Map<string, weak DocumentPanel> panels = new Gee.HashMap<string, weak DocumentPanel>();
	static Gee.List<string> ids = new Gee.ArrayList<string>();

	// For generating unique
	static int id_count = 0;

	string _title;
	public string title
	{
		get
		{
			return _title;
		}

		set
		{
			_title = value;
			command = @"document.new $_title $id";
		}
	}

	public string command { get; set; }
	public string id { get; construct set; }
	public Gtk.TextView doc { get; construct set; }

	public DocumentPanel.from_cache (string title, string id)
	{
		Object (id: id, doc: new Gtk.TextView (), margin_top: 5, title: title,
			command: @"document.new $title $id");

		var id_str = int.parse (id) + 1;
		if (id_count < id_str)
			id_count = id_str;

		try
		{
			var file = File.new_for_path (@"./cache/document/$id");
			if (file.query_exists ())
			{
				char[] contents;
				file.load_contents (null, out contents, null);
				doc.buffer.text = (string) contents;
			}
		} catch (Error e)
		{
			stdout.puts (@"Error in DocumentPanel.from_cache: $(e.message)");
		}
	}

	public DocumentPanel (string title)
	{
		var id = id_count++.to_string ();
		Object (id: id, doc: new Gtk.TextView (), margin_top: 5, title: title,
			command: @"document.new $title $id");
	}

	construct
	{
		// Register id
		panels[id] = this;
		ids.add (id);

		// Set up View
		add (doc);
		doc.visible = true;
		visible = true;
		doc.set_border_window_size (Gtk.TextWindowType.TOP, 4);

		doc.buffer.delete_range.connect (notify_state);
		doc.buffer.insert_text.connect (notify_state);

		// Line numbers
		new Gutter (doc);
	}

	~DocumentPanel ()
	{
		cache ();
		panels.unset (id);
		ids.remove (id);
	}

	bool timeout = false;
	void notify_state ()
	{
		// Saving state
		if (timeout)
			return;

		timeout = true;
		Timeout.add_seconds (30, () =>
		{
			timeout = false;
			cache ();
			return false;
		});
	}

	void cache ()
	{
		try
		{
			var file = File.new_for_path (@"./cache/document/$id");
			var dir = file.get_parent ();
			if (!dir.query_exists ())
				dir.make_directory_with_parents ();

			if (file.query_exists ())
				file.replace_contents (doc.buffer.text.data, null, true, FileCreateFlags.NONE, null);
			else
			{
				var os = file.create (FileCreateFlags.NONE);
				os.write (doc.buffer.text.data);
				os.close ();
			}
		} catch (Error e)
		{
			stdout.puts (@"Error in DocumentPanel's cache: $(e.message)");
		}
	}

	/*
	 *  Get instance by id
	 */
	public static new DocumentPanel get (string id)
	{
		return panels[id];
	}

	/*
	 *  Get id by index to pass to get ()
	 */
	public static string? get_id_by_index (int index)
	{
		return index < ids.size ? ids[index] : null;
	}
}
