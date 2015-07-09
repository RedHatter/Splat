/*************************************************************************
 *  Stack.vala
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

class Stack
{
	public class Context
	{
		public Gee.List<Json.Object> patterns;
		public Json.Object obj;
		public string scope;
		public int line;
		public int end;
		public int offset;

		private Json.Parser lang;

		public Context (Json.Object? obj, Json.Parser lang)
		{
			this.obj = obj;
			patterns = new Gee.LinkedList<Json.Object>();
			this.lang = lang;
		}

		public void add_all (Json.Array array)
		{
			array.foreach_element ((array, index, node) =>
			{
				var obj = node.get_object ();
				if (obj.has_member ("include"))
				{
					var include_str = obj.get_member ("include").get_string ();
					include_str = include_str[1:include_str.length];

					var repo = lang.get_root ().get_object ().get_member ("repository").get_object ();
					if (repo.has_member (include_str))
					{
						obj = repo.get_member (include_str).get_object ();
						if (obj.has_member ("patterns") && !obj.has_member ("begin") && !obj.has_member ("match"))
							add_all (obj.get_member ("patterns").get_array ());
						else if (!patterns.contains (obj))
							patterns.add (obj);
					}
				} else if (!patterns.contains (obj))
					patterns.add (obj);
			});
		}

		// public void print ()
		// {
		// 	stdout.printf("\n\n-- %d:%s --\n", line, scope);
		// 	foreach (var obj in patterns)
		// 	{
		// 		stdout.printf("----\n");
		// 		if (obj.has_member ("name")) stdout.printf("name: %s\n", obj.get_member ("name").get_string ());
		// 		if (obj.has_member ("match")) stdout.printf("match: %s\n", obj.get_member ("match").get_string ());
		// 		if (obj.has_member ("begin")) stdout.printf("begin: %s\n", obj.get_member ("begin").get_string ());
		// 		if (obj.has_member ("end")) stdout.printf("end: %s\n", obj.get_member ("end").get_string ());
		// 		if (obj.has_member ("captures") || obj.has_member ("endCaptures") || obj.has_member ("beginCaptures")) stdout.printf("captures: yes\n");
		// 	}
		// }
	}

	private Gee.List<Context> stack;
	private int _head = -1;
	public Context head { owned get { return stack[_head]; } }

	public Stack ()
	{
		stack = new Gee.LinkedList<Context> ();
	}

	public void up ()
	{
		_head++;
	}

	public void down ()
	{
		_head--;
	}

	public void add (Context ctx)
	{
		stack.insert (++_head, ctx);
	}

	public void update (int after, int amount)
	{
		for (var i = 0; i < stack.size; i++)
			if (stack[i].line > after)
			{
				stack[i].line += amount;
				stack[i].end += amount;
			}
	}

	public void set_by_line (int line)
	{
		_head = 0;
		for (var i = 0; i < stack.size; i++)
			if (stack[i].line < line && stack[i].end >= line
				&& stack[i].line > stack[_head].line)
				_head = i;
	}

	public void clear_line (int line)
	{
		for (var i = 0; i < stack.size; i++)
			if (stack[i].line == line)
				stack.remove_at (i--);
	}
}
