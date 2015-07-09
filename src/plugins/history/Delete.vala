/*************************************************************************
 *  Delete.vala
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


public class Delete : Action, GLib.Object
{
	public string text { get; set; }
	public int end { get; set; }
	int _start;
	public int start
	{ 
		get
		{
			return _start;
		}

		set
		{
			_start = value;
			Gtk.TextIter iter;
			buffer.get_iter_at_offset (out iter, start);
			line_str = @"$(iter.get_line ()+1):$(iter.get_line_offset ()+1)";
		}
	}

	string line_str;
	Gtk.TextBuffer buffer;

	public Delete (Gtk.TextBuffer buffer, int start, int end, string text)
	{
		this.buffer = buffer;
		this.start = start;
		this.end = end;
		this.text = text;
	}

	public void redo ()
	{
		Gtk.TextIter start_iter, end_iter;
		buffer.get_iter_at_offset (out start_iter, start);
		buffer.get_iter_at_offset (out end_iter, end);
		var range = buffer.get_text (start_iter, end_iter, true);
		if (range == text)
			buffer.delete_range (start_iter, end_iter);
		else
			stdout.puts (@"Attempting to redo delete with invalid state. '$range' '$text'\n");
	}

	public void undo ()
	{
		Gtk.TextIter start_iter;
		buffer.get_iter_at_offset (out start_iter, start);
		buffer.insert (ref start_iter, text, text.length);
	}

	public bool merge (Action action)
	{
		if (!(action is Delete))
			return false;

		if (action.start == end)
		{
			end = action.end;
			text += action.text;
		} else if (action.end == start)
		{
			start = action.start;
			text = action.text + text;
		} else
			return false;

		return true;
	}

	public string render ()
	{
		return @"<span color=\"gray\">$line_str</span> <span color=\"red\" weight=\"bold\">-</span> $text";
	}
}
