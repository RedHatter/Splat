/*************************************************************************
 *  PanelContainer.vala
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
 *  Bridge between Panel and UIManager.
 */
using Gtk;

class PanelContainer : Buildable, Overlay
{
	libsplat.Panel panel;
	Container overlay;

	public string command
	{
		get
		{
			return panel.command;
		}
	}

	string _type;
	public string type_id
	{
		get
		{
			if (_type == null)
				_type = panel.get_type ().name ();

			return _type;
		}
	}

	public PanelContainer (libsplat.Panel panel)
	{
		add (panel);
		this.panel = panel;
		panel.activate.connect(() =>
		{
			var nb = parent as Notebook;
			if (nb != null)
				nb.page = nb.page_num (this);

			(parent.get_toplevel () as Window).present ();
		});

		// Receive enter/leave events
		var events = new EventBox ();
		events.set_size_request (100, 50);
		events.halign = Align.END;
		events.valign = Align.START;
		events.visible = true;
		add_overlay (events);

		// Container for buttons
		overlay = new Box (Orientation.HORIZONTAL, 0);
		overlay.margin = 15;
		var style_context = overlay.get_style_context();
		style_context.add_class(STYLE_CLASS_LINKED);

		overlay.visible = false;
		events.add (overlay);
		events.enter_notify_event.connect ((e) =>
		{
			overlay.visible = true;
			return true;
		});
		events.leave_notify_event.connect ((e) =>
		{
			// Don't hide on button hover
			Allocation allocation;
			int x, y;
			overlay.get_allocation (out allocation);
			events.translate_coordinates (overlay, (int) e.x, (int) e.y, out x, out y);
			if (x > allocation.width || x < 0 || y > allocation.height || y < 0)
				overlay.visible = false;

			return true;
		});
	}

	public void add_handle (Gtk.Widget widget)
	{
		overlay.add (widget);
	}

	public Gtk.Widget get_title ()
	{
		var label = new Gtk.Label (panel.title);
		panel.notify["title"].connect((s, p) => label.label = panel.title);

		return label;
	}
}
