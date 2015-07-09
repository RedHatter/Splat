/*************************************************************************
 *  BuildableList.vala
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
 *  Serilizable (buildable) array list.
 */
using Gtk;

public class BuildableList : Buildable, GLib.Object
{
	public int size { get { return list.size; } }
	Gee.List<Object> list = new Gee.ArrayList<Object> ();

	public void add_child (Builder builder, Object child, string? type)
	{
		list.add (child);
	}

	public new Object get (int i)
	{
		return list[i];
	}

	public void custom_finished (Builder builder, Object? child, string tagname, void* data) {}
	public void custom_tag_end (Builder builder, Object? child, string tagname, out void* data) {}
	public bool custom_tag_start (Builder builder, Object? child, string tagname, out MarkupParser parser, out void* data) { return false; }
	public void parser_finished (Builder builder) {}
	public void set_buildable_property (Builder builder, string name, Value value) {}
	public void set_name (string name) {}
	public unowned string get_name () { return ""; }
	public Object construct_child (Builder builder, string name) { return null; }
	public unowned Object get_internal_child (Builder builder, string childname) { return null; }
}
