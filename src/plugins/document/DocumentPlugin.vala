/*************************************************************************
 *  DocumentPlugin.vala
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

using libsplat;

public class DocumentPlugin : GLib.Object
{
	public string active_id { get; private set; }

	public void init ()
	{
		PluginManager.instance.register_command ("document.new", new_view);
		PluginManager.instance.register_command ("document.insert", insert);
		PluginManager.instance.register_command ("document.contents", contents);
		PluginManager.instance.register_command ("document.active", active);
	}

	/*
	 *  Usage: document.new [title=Untitled] [id?]
	 *   Creates a new document named [title].
	 *   If [id] is set will attempt to load contents from cache.
	 *   Returns the document id.
	 *
	 */
	public string? new_view (string[] args)
	{
		var title = args[0] != null ? args[0] : "Untitled";
		// var panel = args[1] == new DocumentPanel (title) : new DocumentPanel.from_cache (title, args[1]);
		var panel = new DocumentPanel (title);
		var font = @"$(Preferences.instance.get_string ("font_face")) $(Preferences.instance.get_int ("font_size"))";
		panel.doc.override_font (Pango.FontDescription.from_string (font));
		panel.doc.focus_in_event.connect ((e) =>
		{
			active_id = panel.id;
			return true;
		});

		active_id = panel.id;
		PluginManager.instance.open_panel (panel);

		return panel.id;
	}

	/*
	 *  Usage: insert [id] [text] [location=?]
	 *   Inserts [text] at [location] in document signified by [id].
	 *   [location] defaults to end of document
	 */
	public string? insert (string[] args)
	{
		var id = args[0];
		var text = args[1];
		if (id == null || text == null)
			return null;

		var doc = get_view (id);

		if (doc != null)
		{
			var buffer = doc.buffer.text;
			var location = args[2] == null ? buffer.length : int.parse (args[2]);
			if (buffer == null)
				doc.buffer.text = text;
			else
				doc.buffer.text = buffer[0:location] + text + buffer[location:buffer.length];
		}

		return null;
	}

	/*
	 *  Usage: delete [id] [start] [end]
	 *   Removes the segment [start] to [end] of the document signified by [id].
	 */
	public string? delete (string[] args)
	{
		var id = args[0];
		var start = args[1];
		var end = args[2];
		if (id == null || start == null || end == null)
			return null;

		var doc = get_view (id);
		doc.buffer.text = doc.buffer.text[0:int.parse (start)] + doc.buffer.text[int.parse (end):-1];

		return null;
	}

	/*
	 *  Usage: contents [id] [start=0] [end=?]
	 *   Returns the segment [start] to [end] of the document signified by [id].
	 *   [end] defaults to the end of the document.
	 */
	public string? contents (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		var doc = get_view (id);
		var start = args[1] == null ? 0 : int.parse (args[1]);
		var end = args[2] == null ? doc.buffer.text.length : int.parse (args[2]);
		return doc.buffer.text[start:end];
	}

	/*
	 *  Usage: active
	 *   Returns the last active (focused) document.
	 */
	public string? active (string[] args)
	{
		return active_id;
	}

	public Gtk.TextView get_view (string id)
	{
		return DocumentPanel.get (active_id).doc;
		// return (Gtk.TextView) ((Gtk.Bin) panels[id].widget).get_child ();
	}

	public string? get_id_by_index (int index)
	{
		return DocumentPanel.get_id_by_index (index);
	}

	public void set_active (string id)
	{
		active_id = id;
		DocumentPanel.get (id).activate ();
	}
}
