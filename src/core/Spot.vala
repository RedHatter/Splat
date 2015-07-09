/*************************************************************************
 *  Spot.vala
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
 *  Simple window to show an area a Panel can be dropped.
 */
class Spot : Gtk.Window
{
	public delegate void Callback (PanelContainer ctn, Notebook nb);

	Notebook nb;
	Gdk.Rectangle bounds;
	Callback callback;

	public Spot (int x, int y, int width, int height, Notebook nb, owned Callback c)
	{
		this.nb = nb;
		callback = (owned) c;
		bounds = Gdk.Rectangle ()
		{
			x = x,
			y = y,
			width = width,
			height = height
		};
		this.nb = nb;
		decorated = false;
		skip_taskbar_hint = true;
		skip_pager_hint = true;
		app_paintable = true;
		can_focus = false;
		opacity = 0.5;
		override_background_color (Gtk.StateFlags.NORMAL, Gdk.RGBA ()
			{
				red = 0,
				green = 0,
				blue = 1,
				alpha = 1
			});
		set_default_size (width, height);
		show_all ();
		move (x, y);
	}

	public bool contains (int x, int y)
	{
		return bounds.x <= x && bounds.x + bounds.width >= x &&
				bounds.y <= y && bounds.y + bounds.height >= y;
	}

	public void drop (PanelContainer ctn)
	{
		callback (ctn, nb);
	}
}
