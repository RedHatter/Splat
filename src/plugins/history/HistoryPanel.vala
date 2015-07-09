/*************************************************************************
 *  HisotryPanel.vala
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


using Gtk;

class HistoryPanel : libsplat.Panel, TreeView
{
	public string title { get; set; }
	public string command
	{
		get
		{
			return "history.panel";
		}

		set {}
	}

	public HistoryPanel ()
	{
		Object (title: "History");
	}

	construct
	{
		Gtk.CellRenderer cell = new CellRendererAction ();
		insert_column_with_attributes (-1, null, cell, "action", 0, "enabled", 1);
	}
}
