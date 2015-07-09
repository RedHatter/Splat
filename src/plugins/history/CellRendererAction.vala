/*************************************************************************
 *  CellRendererAction.vala
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

class CellRendererAction : Gtk.CellRendererText {
	public Action action { get; set; }
	public bool enabled { get; set; }

	public override void render (Cairo.Context ctx, Gtk.Widget widget,
								 Gdk.Rectangle background_area,
								 Gdk.Rectangle cell_area,
								 Gtk.CellRendererState flags)
	{
		if (!enabled)
			background = "light gray";
		else
			background_set = false;

		var text = action.render ();
		if ((flags & Gtk.CellRendererState.SELECTED) == Gtk.CellRendererState.SELECTED)
		{
			try
			{
				var regex = new Regex ("<.+?>");
				text = regex.replace (text, text.length, 0, "");
			} catch (RegexError e)
			{
				stdout.puts (@"Error in CellRendererAction: $(e.message)");
			}
		}

		markup = text;
		base.render (ctx, widget, background_area, cell_area, flags);
	}
}
