/*************************************************************************
 *  SearchPlugin.vala
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
 * TODO: Multi-line entries. Find all dialog. Find highlight.
 * Quick find. Goto line. Remove set_search? Show regex error?
 */

using Gtk;
using libsplat;

public class SearchPlugin : GLib.Object
{
	public const uint8 REGEX = 1 << 0;
	public const uint8 CASELESS = 1 << 1;

	public const uint8 SCOPE_FILE = 1 << 2;
	public const uint8 SCOPE_ALL_FILES = 1 << 3;
	public const uint8 SCOPE_SELECTION = 1 << 4;

	uint8 flags = CASELESS|SCOPE_FILE;

	Regex regex;
	public string search = "";
	public string replace_with = "";
	int pos;

	int file_index;

	public void init (PluginManager pm)
	{
		PluginManager.instance.register_command ("search.panel", search_panel);
		PluginManager.instance.register_command ("search.set_search", set_search_cmd);
		PluginManager.instance.register_command ("search.find_next", find_next);
		PluginManager.instance.register_command ("search.find_prv", find_prv);
		PluginManager.instance.register_command ("search.replace", replace_all);
		PluginManager.instance.register_command ("search.replace_all", replace_all);
	}

	public string active_id ()
	{
		return PluginManager.instance.call_command ("document.active");
	}

	/*
	 *  search.panel
	 *   Opens find panel.
	 */
	public string? search_panel (string[] args)
	{
		PluginManager.instance.open_panel (new SearchPanel (this));
		return null;
	}

	/*
	 *  search.set_flags [flag] ...
	 *   Set all [flag]s to true.
	 *   flags
	 *   -----
	 *   REGEX				Is search a regular expression?
	 *   CASELESS			Is search case sensitive?
	 *   SCOPE_FILE			Search in active file.
	 *   SCOPE_ALL_FILES	Search in all open files.
	 *   SCOPE_SELECTION	Search in selection.
	 */
	public string? set_flags (string[] args)
	{
		foreach (var arg in args)
		{
			switch (arg.down ())
			{
				case "regex":
					set_flag (REGEX, true);
					break;
				case "case":
					set_flag (CASELESS, true);
					break;
				case "scope_file":
					set_flag (SCOPE_FILE, true);
					break;
				case "scope_all_files":
					set_flag (SCOPE_ALL_FILES, true);
					break;
				case "scope_selection":
					set_flag (SCOPE_SELECTION, true);
					break;
			}
		}

		return null;
	}

	/*
	 *  search.clear_flags [flag] ...
	 *   Set all [flag]s to false.
	 *   flags
	 *   flags
	 *   -----
	 *   REGEX				Is search a regular expression?
	 *   CASELESS			Is search case sensitive?
	 *   SCOPE_FILE			Search in active file.
	 *   SCOPE_ALL_FILES	Search in all open files.
	 *   SCOPE_SELECTION	Search in selection.
	 */
	public string? clear_flags (string[] args)
	{
		foreach (var arg in args)
		{
			switch (arg.down ())
			{
				case "regex":
					set_flag (REGEX, false);
					break;
				case "case":
					set_flag (CASELESS, false);
					break;
				case "scope_file":
					set_flag (SCOPE_FILE, false);
					break;
				case "scope_all_files":
					set_flag (SCOPE_ALL_FILES, false);
					break;
				case "scope_selection":
					set_flag (SCOPE_SELECTION, false);
					break;
			}
		}

		return null;
	}

	public void set_flag (uint8 flag, bool state)
	{
		if (state)
		{
			uint8 scopes = SCOPE_FILE|SCOPE_SELECTION|SCOPE_ALL_FILES;
			if ((flag & scopes) != 0)
			{
				scopes &= ~flag;
				flags &= ~scopes;
			}

			flags |= flag;
		} else
			flags &= ~flag;
	}

	public bool is_flag (uint8 flag)
	{
		return (flags & flag) == flag;
	}

	/*
	 *  search.set_search [search] [replace]
	 *   [search] the string to search for.
	 *   [replace] string to replace with.
	 */
	public string? set_search_cmd (string[] args)
	{
		var str = args[0];
		var replace = args[1];
		if (str == null)
			return null;

		set_search (str, replace);

		return null;
	}

	public void set_search (string str, string? replace_with)
	{
		pos = -1;
		file_index = 0;
		this.replace_with = replace_with;

		var mask = RegexCompileFlags.MULTILINE;
		if (is_flag (CASELESS))
			mask |= GLib.RegexCompileFlags.CASELESS;

		try { regex = new Regex (str, mask); }
		catch (RegexError e) { stdout.puts (@"Error in find_next: $(e.message)\n"); }

		search = str;
	}

	/*
	 *  search.find_next [id] [pos=?]
	 *   Use options set in set_search to find next string.
	 *   [pos] defaults to last match or cursor position.
	 */
	public string? find_next (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		var document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		var doc = document.get_view (id);

		if (args[1] != null)
			pos = int.parse (args[1]);
		else if (pos < 0)
			pos = doc.buffer.cursor_position;

		int start = -1;
		int end = -1;
		try
		{
			if (is_flag (SCOPE_FILE))
			{
				var buffer = doc.buffer.text;
				if (!is_flag (REGEX))
				{
					if (is_flag (CASELESS))
						start = buffer.down ().index_of (search.down (), pos);
					else
						start = buffer.index_of (search, pos);
					end = start + search.length;
				} else
				{
					MatchInfo info;
					regex.match_full (buffer, -1, pos, 0, out info);
					info.fetch_pos (0, out start, out end);
				}
			} else if (is_flag (SCOPE_SELECTION))
			{
				var buffer = doc.buffer.text;
				TextIter sel_start, sel_end;
				if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
					return null;

				if (!is_flag (REGEX))
				{
					start = buffer[0:sel_end.get_offset ()].index_of (search, sel_start.get_offset ());
					end = start + search.length;
				} else
				{
					MatchInfo info;
					regex.match_full (buffer, sel_end.get_offset (), sel_start.get_offset (), 0, out info);
					info.fetch_pos (0, out start, out end);
				}
			} else if (is_flag (SCOPE_ALL_FILES))
			{
				id = document.get_id_by_index (file_index);
				if (id == null)
				{
					file_index = 0;
					pos = -1;
				} else
				{
					doc = document.get_view (id);

					var buffer = doc.buffer.text;
					if (!is_flag (REGEX))
					{
						if (is_flag (CASELESS))
							start = buffer.down ().index_of (search.down (), pos);
						else
							start = buffer.index_of (search, pos);
						end = start + search.length;
					} else
					{
						MatchInfo info;
						regex.match_full (buffer, -1, pos, 0, out info);
						info.fetch_pos (0, out start, out end);
					}

					if (start == -1)
					{
						file_index++;
						pos = -1;
					}
				}
			}
		} catch (RegexError e)
		{
			stdout.puts (@"Error in find_next: $(e.message)\n");
		}

		if (start == -1)
		{
			if (pos != 0)
			{
				pos = 0;
				find_next (new string []{ id });
			}
	
			return null;
		}

		pos = end;

		TextIter start_iter, end_iter;
		doc.buffer.get_iter_at_offset (out start_iter, start);
		doc.buffer.get_iter_at_offset (out end_iter, end);
		doc.buffer.select_range (start_iter, end_iter);

		document.set_active (id);

		doc.scroll_mark_onscreen (doc.buffer.get_selection_bound ());
		doc.scroll_mark_onscreen (doc.buffer.get_insert ());

		return @"$start $end";
	}

	/*
	 *  search.find_prv [id] [pos=?]
	 *   Use options set in set_search to find previous string.
	 *   [pos] defaults to last match or cursor position.
	 */
	public string? find_prv (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		var document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		var doc = document.get_view (id);

		if (args[1] != null)
			pos = int.parse (args[1]);
		else if (pos < 0)
			pos = doc.buffer.cursor_position;

		int start = -1;
		int end = -1;

		if (is_flag (SCOPE_FILE))
		{
			var buffer = pos == 0 ? doc.buffer.text : doc.buffer.text[0:pos-search.length];
			if (is_flag (CASELESS))
				start = buffer.down ().last_index_of (search.down ());
			else
				start = buffer.last_index_of (search);
			end = start + search.length;
		} else if (is_flag (SCOPE_SELECTION))
		{
			var buffer = doc.buffer.text;
			TextIter sel_start, sel_end;
			if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
				return null;

			if (is_flag (CASELESS))
				start = buffer[0:sel_end.get_offset ()].down ().index_of (search.down (), sel_start.get_offset ());
			else
				start = buffer[0:sel_end.get_offset ()].index_of (search, sel_start.get_offset ());
			end = start + search.length;
		} else if (is_flag (SCOPE_ALL_FILES))
		{
			id = document.get_id_by_index (file_index);
			if (id == null)
			{
				file_index = 0;
				pos = -1;
			} else
			{
				doc = document.get_view (id);

				var buffer = pos == 0 ? doc.buffer.text : doc.buffer.text[0:pos-search.length];

				if (is_flag (CASELESS))
					start = buffer.down ().index_of (search.down ());
				else
					start = buffer.index_of (search);
				end = start + search.length;

				if (start == -1)
				{
					file_index++;
					pos = -1;
				}
			}
		}
		if (start == -1)
		{
			if (pos != 0)
			{
				pos = 0;
				find_prv (new string []{ id });
			}
	
			return null;
		}

		pos = end;

		TextIter start_iter, end_iter;
		doc.buffer.get_iter_at_offset (out start_iter, start);
		doc.buffer.get_iter_at_offset (out end_iter, end);
		doc.buffer.select_range (start_iter, end_iter);

		document.set_active (id);

		doc.scroll_mark_onscreen (doc.buffer.get_selection_bound ());
		doc.scroll_mark_onscreen (doc.buffer.get_insert ());

		return @"$start $end";
	}

	/*
	 *  search.replace_all [id]
	 *   Use options set in set_search to replace all occurrences of the search string.
	 */
	public string? replace_all (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		var document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		var doc = document.get_view (id);
		doc.buffer.begin_user_action ();
		try
		{
			if (is_flag (SCOPE_FILE))
			{
				MatchInfo info;
				var buffer = doc.buffer.text;
				if (!is_flag (REGEX))
				{
					int start = -1;
					if (is_flag (CASELESS))
						start = buffer.down ().index_of (search.down ());
					else
						start = buffer.index_of (search);

					while (start != -1)
					{
						TextIter start_iter, end_iter;
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.get_iter_at_offset (out end_iter, start+search.length);

						doc.buffer.delete_range (start_iter, end_iter);
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.insert (ref start_iter, replace_with, replace_with.length);

						buffer = doc.buffer.text;

						if (is_flag (CASELESS))
							start = buffer.down ().index_of (search.down ());
						else
							start = buffer.index_of (search);
					}
				} else
					while (regex.match (buffer, 0, out info))
					{
						int start, end;
						info.fetch_pos (0, out start, out end);
						TextIter start_iter, end_iter;
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.get_iter_at_offset (out end_iter, end);

						doc.buffer.delete_range (start_iter, end_iter);
						var expanded = info.expand_references (replace_with);
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.insert (ref start_iter, expanded, expanded.length);
						buffer = doc.buffer.text;
					}
			} else if (is_flag (SCOPE_SELECTION))
			{
				MatchInfo info;
				TextIter sel_start, sel_end;
				if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
					return null;

				var buffer = doc.buffer.get_text (sel_start, sel_end, true);
				var sel = sel_start.get_offset ();
				// var buffer = doc.buffer.text;

				if (!is_flag (REGEX))
				{
					int start = -1;
					if (is_flag (CASELESS))
						start = buffer.down ().index_of (search.down ());
					else
						start = buffer.index_of (search);

					start += sel;

					while (start != sel-1)
					{
						TextIter start_iter, end_iter;
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.get_iter_at_offset (out end_iter, start+search.length);

						doc.buffer.delete_range (start_iter, end_iter);
						doc.buffer.get_iter_at_offset (out start_iter, start);
						doc.buffer.insert (ref start_iter, replace_with, replace_with.length);

						// buffer = doc.buffer.text;
						if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
							return null;

						buffer = doc.buffer.get_text (sel_start, sel_end, true);
						sel = sel_start.get_offset ();

						if (is_flag (CASELESS))
							start = buffer.down ().index_of (search.down ());
						else
							start = buffer.index_of (search);

						start += sel;
					}
				} else
					while (regex.match (buffer, 0, out info))
					{
						int start, end;
						info.fetch_pos (0, out start, out end);
						TextIter start_iter, end_iter;
						doc.buffer.get_iter_at_offset (out start_iter, start+sel);
						doc.buffer.get_iter_at_offset (out end_iter, end+sel);

						doc.buffer.delete_range (start_iter, end_iter);
						var expanded = info.expand_references (replace_with);
						doc.buffer.get_iter_at_offset (out start_iter, start+sel);
						doc.buffer.insert (ref start_iter, expanded, expanded.length);

						if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
							return null;

						buffer = doc.buffer.get_text (sel_start, sel_end, true);
						sel = sel_start.get_offset ();
					}
			} else if (is_flag (SCOPE_ALL_FILES))
			{
				var index = 0;
				id = document.get_id_by_index (index);

				while (id != null)
				{
					doc = document.get_view (id);

					MatchInfo info;
					var buffer = doc.buffer.text;
					if (!is_flag (REGEX))
					{
						int start = -1;
						if (is_flag (CASELESS))
							start = buffer.down ().index_of (search.down ());
						else
							start = buffer.index_of (search);

						while (start != -1)
						{
							TextIter start_iter, end_iter;
							doc.buffer.get_iter_at_offset (out start_iter, start);
							doc.buffer.get_iter_at_offset (out end_iter, start+search.length);

							doc.buffer.delete_range (start_iter, end_iter);
							doc.buffer.get_iter_at_offset (out start_iter, start);
							doc.buffer.insert (ref start_iter, replace_with, replace_with.length);

							buffer = doc.buffer.text;

							if (is_flag (CASELESS))
								start = buffer.down ().index_of (search.down ());
							else
								start = buffer.index_of (search);
						}
					} else
						while (regex.match (buffer, 0, out info))
						{
							int start, end;
							info.fetch_pos (0, out start, out end);
							TextIter start_iter, end_iter;
							doc.buffer.get_iter_at_offset (out start_iter, start);
							doc.buffer.get_iter_at_offset (out end_iter, end);

							doc.buffer.delete_range (start_iter, end_iter);
							var expanded = info.expand_references (replace_with);
							doc.buffer.get_iter_at_offset (out start_iter, start);
							doc.buffer.insert (ref start_iter, expanded, expanded.length);
							buffer = doc.buffer.text;
						}

					id = document.get_id_by_index (++index);
				}
			}
		} catch (RegexError e)
		{
			stdout.puts (@"Error in find_next: $(e.message)\n");
		}

		doc.buffer.end_user_action ();

		return null;
	}

	/*
	 *  search.replace [id] [pos=?]
	 *   Use options set in set_search to find and replace next string.
	 *   [pos] defaults to last match or cursor position.
	 */
	public string? replace (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		var document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		var doc = document.get_view (id);

		TextIter sel_start, sel_end;
		if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
		{
			find_next (args);
			if (!doc.buffer.get_selection_bounds (out sel_start, out sel_end))
				return null;
		}
		
		try
		{
			MatchInfo info = null;
			var sel = doc.buffer.get_text (sel_start, sel_end, true);
			if (!is_flag (REGEX) && sel == search)
			{
				doc.buffer.delete_range (sel_start, sel_end);
				doc.buffer.insert_at_cursor (replace_with, replace_with.length);
			} else if (is_flag (REGEX) && regex.match (sel, RegexMatchFlags.ANCHORED, out info))
			{
				int start, end;
					info.fetch_pos (0, out start, out end);
				if (end == sel.length)
				{
					doc.buffer.delete_range (sel_start, sel_end);
					var expanded = info.expand_references (replace_with);
					doc.buffer.insert_at_cursor (expanded, expanded.length);
				}
			}
		} catch (RegexError e)
		{
			stdout.puts (@"Error in replace: $(e.message)");
		}

		return find_next (args);
	}
}
