/*************************************************************************
 *  Gutter.vala
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
 * Line numbers.
 *
 * TODO: Separate into another plugin.
 */

using Gtk;

public class Gutter : Label
{
	public TextView doc { get; construct; }

	public Pango.Color active_color { get; set; }

	int width;

	int _cursor;
	public int cursor
	{
		get
		{
			return _cursor;
		}

		private set
		{
			_cursor = value;

			var bg = Pango.attr_background_new (active_color.red, active_color.green, active_color.blue);
			bg.start_index = (width + 3) * value;
			bg.end_index = bg.start_index + width + 2;

			attributes = new Pango.AttrList ();
			attributes.insert ((owned) bg);
		}
	}

	int _line_count;
	public int line_count
	{
		get
		{
			return _line_count;
		}

		set
		{
			width = value.to_string ().length;
			if (width < 3)
				width = 3;

			var lines = "";
			for (var i = 1; i <= value; i++)
				lines += " %*d \n".printf (width, i);

			label = lines;
			_line_count = value;
		}
	}

	public Gutter (TextView doc)
	{
		var color = Pango.Color ();
		color.parse ("#3E3D32");
		Object (visible: true, line_count: 1, doc: doc, active_color: color);
	}

	construct
	{
		override_color (StateFlags.NORMAL, Gdk.RGBA ()
		{
			red = 0.7,
			green = 0.7,
			blue = 0.7,
			alpha = 1
		});

		size_allocate.connect ((allocation) => calc_width ());

		doc.set_border_window_size (TextWindowType.LEFT, 1);
		doc.add_child_in_window (this, TextWindowType.LEFT, 0, 0);
		doc.buffer.delete_range.connect_after ((start, end) => line_count = doc.buffer.get_line_count ());
		doc.buffer.insert_text.connect_after ((ref pos, text, length) =>
		{
			if ("\n" in text)
				line_count = doc.buffer.get_line_count ();
		});
		doc.buffer.notify["cursor-position"].connect (() =>
		{
			TextIter iter;
			doc.buffer.get_iter_at_offset (out iter, doc.buffer.cursor_position);
			cursor = iter.get_line ();
		});
	}

	int last_width = 0;
	public void calc_width ()
	{
		int width;
		get_layout ().get_pixel_size (out width, null);
		if (width != last_width)
		{
			last_width = width;
			doc.set_border_window_size (TextWindowType.LEFT, width+5);
		}
	}
}
