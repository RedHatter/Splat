/*************************************************************************
 *  Notebook.vala
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
 *  Extended Notebook to support buildable panels (custom command tag).
 */
public class Notebook : Gtk.Notebook, Gtk.Buildable
{
	public string guid { get; set; }

	public bool custom_tag_start (Gtk.Builder builder, Object? child, string tagname, out MarkupParser parser, out void* data)
	{
		data = null;
		parser = MarkupParser ()
		{
			text = (context, text, text_len) =>
			{
				libsplat.PluginManager.instance.call_command_str (text);
			}
		};
		
		return true;
	}

	construct
	{
		if (guid == null)
			guid = DBus.generate_guid ();

		UIManager.instance.register_notebook (this);

		page_added.connect (() => show_tabs = get_n_pages () > 1);
		page_removed.connect (() => show_tabs = get_n_pages () > 1);
	}
}
