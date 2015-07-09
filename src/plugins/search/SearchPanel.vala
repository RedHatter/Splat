/*************************************************************************
 *  SearchPanel.vala
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

class SearchPanel : libsplat.Panel, Box
{
	public string title { get; set; }
	public string command
	{
		get
		{
			return "search_panel";
		}

		set {}
	}

	public SearchPlugin sp { get; construct; }

	public SearchPanel (SearchPlugin sp)
	{
		Object(margin: 20, orientation: Orientation.VERTICAL, title: "Find and Replace", sp: sp);
	}

	construct
	{
		var box = new Box (Orientation.HORIZONTAL, 0);
		add (box);
		var swap = new Button.with_label ("↕");
		box.add (swap);
		swap.relief = ReliefStyle.NONE;
		var inputs = new Box (Orientation.VERTICAL, 5);
		box.pack_start (inputs, true, true, 0);

		var find = new Entry ();
		inputs.add (find);
		find.text = sp.search;
		find.placeholder_text = "Find...";
		find.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
		find.icon_press.connect ((pos, event) => find.set_text (""));
		var replace = new Entry ();
		inputs.add (replace);
		replace.text = sp.replace_with;
		replace.changed.connect (() => sp.set_search (find.text, replace.text));
		replace.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
		replace.icon_press.connect ((pos, event) => replace.set_text (""));
		replace.placeholder_text = "Replace...";
		find.changed.connect (() => sp.set_search (find.text, replace.text));

		swap.clicked.connect (() =>
		{
			var temp = find.text;
			find.text = replace.text;
			replace.text = temp;
		});

		box = new Box (Orientation.HORIZONTAL, 10);
		add (box);
		var find_next = new Button.with_label ("Find Next");
		box.add (find_next);
		var find_prv = new Button.with_label ("Find Previous");
		box.add (find_prv);
		var replace_next = new Button.with_label ("Replace");
		box.add (replace_next);
		var replace_all = new Button.with_label ("Replace All");
		box.add (replace_all);

		box = new Box (Orientation.HORIZONTAL, 50);
		add (box);

		var group = new Box (Orientation.VERTICAL, 0);
		box.add (group);
		var sel = new RadioButton.with_label_from_widget (null, "Selection");
		group.add (sel);
		sel.active = sp.is_flag (SearchPlugin.SCOPE_SELECTION);
		sel.toggled.connect (() => sp.set_flag (SearchPlugin.SCOPE_SELECTION, sel.active));
		var file = new RadioButton.with_label_from_widget (sel, "File");
		group.add (file);
		file.active = sp.is_flag (SearchPlugin.SCOPE_FILE);
		file.toggled.connect (() => sp.set_flag (SearchPlugin.SCOPE_FILE, file.active));
		var all = new RadioButton.with_label_from_widget (sel, "All Files");
		group.add (all);
		all.active = sp.is_flag (SearchPlugin.SCOPE_ALL_FILES);
		all.toggled.connect (() => sp.set_flag (SearchPlugin.SCOPE_ALL_FILES, all.active));

		group = new Box (Orientation.VERTICAL, 0);
		box.add (group);
		var regex = new CheckButton.with_label ("Regular Expression");
		group.add (regex);
		regex.active = sp.is_flag (SearchPlugin.REGEX);
		regex.toggled.connect (() =>
		{
			sp.set_flag (SearchPlugin.REGEX, regex.active);
			find_prv.sensitive = !regex.active;
		});
		var case_sen = new CheckButton.with_label ("Case Sensitive");
		group.add (case_sen);
		case_sen.active = !sp.is_flag (SearchPlugin.CASELESS);
		case_sen.toggled.connect (() =>
		{
			sp.set_flag (SearchPlugin.CASELESS, !case_sen.active);
			sp.set_search (find.text, replace.text);
		});
		// check = new CheckButton.with_label ("Preserve Case");
		// group.add (check);

		find_next.clicked.connect (() => 
			sp.find_next (new string[]{ sp.active_id () }));

		find_prv.clicked.connect (() => 
			sp.find_prv (new string[]{ sp.active_id () }));

		replace_all.clicked.connect (() => 
			sp.replace_all (new string[]{ sp.active_id () }));

		replace_next.clicked.connect (() => 
			sp.replace (new string[]{ sp.active_id () }));
	}
}
