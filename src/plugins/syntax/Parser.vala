/*************************************************************************
 *  Parser.vala
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

class Parser
{
	Gtk.TextView doc;

	Json.Parser lang;
	Json.Parser theme;
	Gee.Map<string, Regex> regex_cache;
	Gee.Map<string, Json.Object> includes;
	Stack stack;

	int line_pos = 0;

	public class Match
	{
		public Gee.List<Capture> captures;
		public Json.Object obj;
		public string scope;
		public int start;
		public int end;
		public int type;

		public Match (MatchInfo match_info, Json.Object obj, string capture_member)
		{
			int start, end;
			match_info.fetch_pos (0, out start, out end);

			if (obj.has_member ("name"))
				scope =  obj.get_member ("name").get_string ();
			captures = new Gee.LinkedList<Capture> ();
			this.obj = obj;
			this.start = start;
			this.end = end;

			if (obj.has_member (capture_member))
			{
				var capture = obj.get_member (capture_member).get_object ();
				foreach (string member in capture.get_members ())
				{
					var scope = capture.get_member (member).get_object ().get_member ("name").get_string ();
					match_info.fetch_pos (int.parse (member), out start, out end);
					if (end != -1 && start != -1)
						captures.add (new Capture ()
						{
							start = start,
							end = end,
							scope = scope
						});
				}
			}
		}
	}

	public class Capture
	{
		public int start;
		public int end;
		public string scope;
	}

	public Parser (Gtk.TextView doc)
	{
		this.doc = doc;

		doc.buffer.delete_range.connect ((start, end) =>
		{
			if (theme == null || lang == null || stack == null)
				return;

			var line = start.get_line ();
			var end_line = end.get_line ();
			stack.update (line, line-end_line);
			do
				stack.clear_line (line++);
			while (line <= end_line);
		});
		doc.buffer.delete_range.connect_after ((start, end) =>
		{
			if (theme == null || lang == null || stack == null)
				return;

			invalidate (start.get_line ());
		});
		doc.buffer.insert_text.connect_after ((ref pos, new_text, new_text_length) =>
		{
			if (theme == null || lang == null)
				return;

			// Ending line
			int line = pos.get_line ();

			int count = new_text.split ("\n").length-1;
			if (count < 1)
				count = 0;
			else
				stack.update (line, count);

			try
			{
				for (var i = count; i >= 0; i--)
				{
					Gtk.TextIter start, end;
					doc.buffer.get_iter_at_line (out start, line - i);
					doc.buffer.get_iter_at_line (out end, line - i);
					if (!end.ends_line ())
						end.forward_to_line_end ();

					invalidate (line - i);
				}
			}
			catch (RegexError e) { stdout.puts (@"Error in Parser constructor: $(e.message)\n"); }
		});
	}

	public void set_lang (Json.Parser lang)
	{
		this.lang = lang;
		regex_cache = new Gee.HashMap<string, Regex>();
		includes = new Gee.HashMap<string, Json.Array>();
		doc.buffer.tag_table.foreach ((tag) => doc.buffer.tag_table.remove (tag));


		if (theme != null && lang != null)
			try { parse_buffer (); }
			catch (RegexError e) { stdout.puts (@"Error settings syntax: $(e.message)\n"); }
	}

	public void set_theme (Json.Parser theme)
	{
		this.theme = theme;
		doc.buffer.tag_table.foreach ((tag) => doc.buffer.tag_table.remove (tag));

		set_defaults ();
		// var color = Pango.Color ();
		// color.parse (theme.get_root ().get_object ().get_member ("settings").get_object ().get_member ("lineHighlight").get_string ());
		// ((Gutter) doc.get_window (Gtk.TextWindowType.LEFT)).active_color = color;

		if (lang != null && theme != null)
			try { parse_buffer (); }
			catch (RegexError e) { stdout.puts (@"Error setting theme: $(e.message)\n"); }
	}

	// private void style_tab ()
	// {
	// 	var settings = theme.get_root ().get_object ();
	// 	var bg = settings.get_member ("background").get_string ();
	// 	var color = settings.get_member ("foreground").get_string ();
	// 	var style_provider = new Gtk.CssProvider ();

	// 	var css = @"
	// 	.linked .button {
	// 		box-shadow: inset -1px 0 shade ($bg, 0.84);
	// 		background-image: -gtk-gradient (linear, left top, left bottom,
 //                                     from ($bg),
 //                                     to (shade ($bg, 0.7)));
	// 		border-image-source: none;
	// 		color: shade ($color, 0.8);
	// 	}
	// 	";

	// 	style_provider.load_from_data (css, css.length);

	// 	stdout.puts (doc.parent.parent.get_type ().name ()+"\n");
	// 	doc.parent.parent.parent.get_style_context ().add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	// }


	public void set_defaults ()
	{
		var settings = theme.get_root ().get_object ();
		if (settings.has_member ("background"))
		{
			var bg = Gdk.RGBA ();
			bg.parse (settings.get_member ("background").get_string ());
			doc.override_background_color (0, bg);
		}

		if (settings.has_member ("foreground"))
		{
			var fg = Gdk.RGBA ();
			fg.parse (settings.get_member ("foreground").get_string ());
			doc.override_color (0, fg);
		}

		if (settings.has_member ("caret"))
		{
			var cursor = Gdk.RGBA ();
			cursor.parse (settings.get_member ("caret").get_string ());
			doc.override_cursor (cursor, null);
		}

		if (settings.has_member ("selection"))
		{
			var bg = Gdk.RGBA ();
			bg.parse (settings.get_member ("selection").get_string ());
			doc.override_background_color (Gtk.StateFlags.SELECTED, bg);
		}
	}

	int dirty_start = 0;
	int dirty_end = 0;
	public void invalidate (int line) throws RegexError
	{
		Gtk.TextIter start;
		doc.buffer.get_iter_at_line (out start, line);
		var end = start;
		if (!end.ends_line ())
			end.forward_to_line_end ();

		stack.set_by_line (line);
		var i = line-1;
		if (dirty_start != line)
			dirty_end = 0;

		do
		{
			stack.clear_line (++i);
			doc.buffer.remove_all_tags (start, end);
			line_pos = 0;
			parse_line (doc.buffer.get_text (start, end, false), i);
			start.forward_line ();
			end.forward_line ();
			if (!end.ends_line ())
				end.forward_to_line_end ();
		}
		while (stack.head.line == i || i < dirty_end);

		dirty_start = line;
		dirty_end = i;
	}

	public void parse_buffer () throws RegexError
	{
		stack = new Stack ();

		var lines = doc.buffer.text.split ("\n");
		var context = new Stack.Context (null, lang);
		context.scope = "root";
		context.add_all (lang.get_root ().get_object ().get_member ("patterns").get_array ());
		stack.add (context);

		for (var i = 0; i < lines.length; i++)
		{
			line_pos = 0;
			parse_line (lines[i], i);
		}
	}

	public void parse_line (string line, int line_num) throws RegexError
	{
		var context = stack.head;
		var matches = new Gee.LinkedList<Match>();
		if (context.obj != null && context.obj.has_member ("end"))
		{
			MatchInfo match_info;
			var regex = get_regex (context.obj.get_member ("end"));
			if (regex.match_full (line, -1, line_pos, 0, out match_info))
			{
				var match = new Match (match_info, context.obj, "endCaptures");
				match.type = 3;
				matches.add (match);
			}
		}

		if (context.patterns != null)
		foreach (var obj in context.patterns)
		{
			MatchInfo match_info;
			if (obj.has_member ("match"))
			{
				Regex regex = get_regex (obj.get_member ("match"));
				if (regex.match_full (line, -1, line_pos, 0, out match_info))
					do
					{
						var match = new Match (match_info, obj, "captures");
						match.type = 1;
						matches.add (match);
					} while (match_info.next ());
			} else if (obj.has_member ("begin"))
			{
				Regex regex = get_regex (obj.get_member ("begin"));
				if (regex.match_full (line, -1, line_pos, 0, out match_info))
				{
					var match = new Match (match_info, obj, "beginCaptures");
					match.type = 2;
					matches.add (match);
				}
			}
		}

		matches.sort ((a, b) => { return a.start - b.start; });

		for (int i = 1; i < matches.size; i++)
			if (matches[i].start < matches[i-1].end)// && matches[i].scope != null && matches[i-1].scope != null) //&& !matches[i].obj.has_member ("begin"))
				matches.remove_at (i--);

		foreach (var match in matches)
		{
			if (match.type == 1)
			{
				if (match.scope != null)
					tag (line_num, match.start, line_num, match.end, match.scope);
				foreach (var capture in match.captures)
					tag (line_num, capture.start, line_num, capture.end, capture.scope);
			} else if (match.type == 2)
			{
				var push = new Stack.Context (match.obj, lang);
				push.scope = match.scope;
				push.line = line_num;
				push.offset = match.start;
				stack.add (push);
				if (match.obj.has_member ("patterns"))
					push.add_all (match.obj.get_member ("patterns").get_array ());

				foreach (var capture in match.captures)
					tag (line_num, capture.start, line_num, capture.end, capture.scope);

				line_pos = match.end;
				parse_line (line, line_num);
				break;
			} else if (match.type == 3)
			{
				context.end = line_num;
				if (context.scope != null)
					tag (context.line, context.offset, line_num, match.end, context.scope);
				foreach (var capture in match.captures)
					tag (line_num, capture.start, line_num, capture.end, capture.scope);

				stack.down ();
				line_pos = match.end;
				parse_line (line, line_num);
				break;
			}
		}
	}

	public void tag (int start_line, int start_offset, int end_line, int end_offset, string scope)
	{
		var tag = doc.buffer.tag_table.lookup (scope);
		if (tag == null)
		{
			tag = doc.buffer.create_tag (scope);
			theme_tag (tag, scope);
		}

		Gtk.TextIter start_iter, end_iter;
		doc.buffer.get_iter_at_line_offset (out start_iter, start_line, start_offset);
		doc.buffer.get_iter_at_line_offset (out end_iter, end_line, end_offset);
		doc.buffer.apply_tag (tag, start_iter, end_iter);
	}

	public void theme_tag (Gtk.TextTag tag, string key)
	{
		string[] keys = key.split (".");
		var obj = theme.get_root ().get_object ();
		foreach (var name in keys)
		{
			if (!obj.has_member (name))
				break;

			obj = obj.get_member (name).get_object ();
			if (obj.has_member ("foreground"))
				tag.foreground = obj.get_member ("foreground").get_string ();

			if (obj.has_member ("background"))
				tag.foreground = obj.get_member ("background").get_string ();

			if (obj.has_member ("fontStyle"))
				tag.font = obj.get_member ("fontStyle").get_string ();
		}
	}

	public Regex get_regex (Json.Node member) throws RegexError
	{
		var str = member.get_string ();
		Regex regex;
		if (regex_cache.has_key (str))
			regex = regex_cache[str];
		else
		{
			regex = new Regex (str, RegexCompileFlags.MULTILINE);
			regex_cache[str] = regex;
		}

		return regex;
	}
}
