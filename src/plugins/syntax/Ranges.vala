/*************************************************************************
 *  Ranges.vala
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

public class Ranges : Object
{
	private class Range
	{
		public int start;
		public int end;

		public Range (int start, int end)
		{
			this.start = start;
			this.end = end;
		}

		public bool contains (int num)
		{
			return num >= start && num <= end;
		}
	}

	Gee.LinkedList<Range> ranges;

	public Ranges ()
	{
		ranges = new Gee.LinkedList<Range> ();
	}

	public bool contains (int start, int end)
	{
		foreach (var range in ranges)
			if (range.contains (start) || range.contains (end))
				return true;

		return false;
	}

	public void add (int start, int end)
	{
		stdout.printf("lock %d:%d\n", start, end);
		int i;
		for (i = 0; i < ranges.size; i++)
			if (ranges[i].start >= start)
				break;

		var merge = false;

		if (ranges.size > i && ranges[i].contains (end))
		{
			merge = true;
			ranges[i].start = start;
		}

		if (i > 0 && ranges[i-1].contains (start) && ranges[i-1].end < end)
		{
			merge = true;
			ranges[i-1].end = end;
		}

		if (i > 0 && ranges.size > i && ranges[i-1].end >= ranges[i].start)
		{
			ranges[i-1].end = ranges[i].end;
			ranges.remove_at (i);
		}

		if (!merge)
			ranges.insert (i, new Range (start, end));
	}
}
