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
	static Gee.Map<string, DocumentPanel> panels = new Gee.HashMap<string, DocumentPanel>();
	static Gee.List<string> ids = new Gee.ArrayList<string>();

	// For generating unique
	static int id_count = 0;

	public string command { get; set; }
	public string title { get; set; }
	public string id { get; private set; }
	public Gtk.TextView doc { get; private set; }

	public DocumentPanel (string title)
	{
		this.title = title;
		command = "document.new";
		margin_top = 5;

		// Set up View
		doc = new Gtk.TextView ();
		add (doc);
		doc.visible = true;
		visible = true;
		doc.set_border_window_size (Gtk.TextWindowType.TOP, 4);

		// Line numbers
		new Gutter (doc);

		// Register id
		id = id_count++.to_string ();
		panels[id] = this;
		ids.add (id);
	}

	~DocumentPanel ()
	{
		panels.unset (id);
		ids.remove (id);
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
