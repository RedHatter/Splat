/*************************************************************************
 *  UI.vala
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
 *  Handles interactions between Panels and the rest of the UI.
 */

using Gtk;
using libsplat;

class UIManager : GLib.Object
{
	Gee.Map<string,Notebook> notebooks = new Gee.HashMap<string,Notebook> ();
	Gee.List<Spot> hotspots = new Gee.ArrayList<Spot> ();
	Gtk.Application app;
	Gee.List<Window> windows = new Gee.ArrayList<Window>();
	Notebook last;
	bool loading = false;

	static UIManager _instance;
	public static UIManager instance
	{
		get
		{
			if (_instance == null)
				_instance = new UIManager ();

			return _instance;
		}
	}

	public void set_app (Gtk.Application app)
	{
		this.app = app;
	}

	public void serialize ()
	{
		var xml = "<interface><object class=\"BuildableList\" id=\"root\">";
		foreach (var win in windows)
		{
			Allocation allocation;
			win.get_child ().get_allocation (out allocation);
			int x, y;
			win.get_position (out x, out y);
			xml += @"<child><object class=\"Window\">
<property name=\"default_height\">$(allocation.height)</property>
<property name=\"default_width\">$(allocation.width)</property>
<property name=\"x\">$x</property>
<property name=\"y\">$y</property>";
			xml += parse_child (win.get_child ());
			xml += "</object></child>";
		}
		xml += "</object></interface>";

		try
		{
			File file = File.new_for_path ("./main.ui");
			FileOutputStream os = file.replace (null, true, FileCreateFlags.NONE);
			os.write (xml.data);
		} catch (Error e)
		{
			stdout.printf ("Error in UIManager.serialize: %s\n", e.message);
		}

	}

	public void unserialize ()
	{
		loading = true;

		var builder = new Gtk.Builder.from_file ("./main.ui");
		var root = builder.get_object ("root") as BuildableList;
		foreach (var obj in root)
		{
			var win = obj as Window;
			win.application = app;
			windows.add (win);
			win.destroy.connect (() =>
			{
				if (win.get_child () != null)
					serialize ();
				windows.remove (win);
			});
			win.show ();
		}

		loading = false;
	}

	private string parse_child (Widget child)
	{
		var xml = "<child>";
		var nb = child as Notebook;
		var paned = child as Paned;
		if (nb != null)
		{
			xml += @"<object class=\"Notebook\"><property name=\"guid\">$(nb.guid)</property>";
			nb.get_children ().foreach ((widget) =>
			{
				var ctn = widget as PanelContainer;
				xml += @"<command>$(ctn.command)</command>";
			});
			xml += "</object>";
		} else if (paned != null)
		{
			xml += @"<object class=\"GtkPaned\"><property name=\"position\">$(paned.position)</property><property name=\"orientation\">$(paned.orientation)</property>";
			paned.get_children ().foreach ((widget) =>
			{
				xml += parse_child (widget);
			});
			xml += "</object>";
		}

		return @"$xml</child>";
	}

	public void register_notebook (Notebook nb)
	{
		var guid = nb.guid;
		nb.visible = true;
		notebooks[guid] = nb;
		last = nb;
		nb.destroy.connect (() =>
		{
			foreach (var entry in notebooks.entries)
				if (entry.value == nb)
				{
					notebooks.unset (entry.key);
					break;
				}
		});
		nb.notify["guid"].connect (() =>
		{
			if (nb.guid == guid)
				return;

			notebooks[nb.guid] = nb;
			notebooks.unset (guid);
		});
	}

	/*
	 *  Show visible marker on edges and center of each Notebook.
	 */
	public void show_hotspots ()
	{
		foreach (var nb in notebooks.values)
		{
			Allocation size;
			nb.get_allocation (out size);
			int root_x, root_y;
			nb.get_window ().get_origin (out root_x, out root_y);

			int w = 20;

			// Top
			hotspots.add (new Spot (root_x + w, root_y, size.width - w*2, w, nb, (ctn, nb) => split (ctn, nb, Orientation.VERTICAL, true)));
			
			// Left
			hotspots.add (new Spot (root_x + size.width - w, root_y + w, w, size.height - w*2, nb, (ctn, nb) => split (ctn, nb, Orientation.HORIZONTAL, false)));
			
			// Bottom
			hotspots.add (new Spot (root_x + w, root_y + size.height - w, size.width - w*2, w, nb, (ctn, nb) => split (ctn, nb, Orientation.VERTICAL, false)));
			
			// Right
			hotspots.add (new Spot (root_x, root_y + w, w, size.height - w*2, nb, (ctn, drop) => split (ctn, drop, Orientation.HORIZONTAL, true)));
			
			// Center
			hotspots.add (new Spot (root_x + w*2, root_y + w*2, size.width - w*4, size.height - w*4, nb, (ctn, nb) => insert (ctn, nb)));
		}
	}

	/*
	 *  Hide hotspot markers.
	 */
	public void hide_hotspots ()
	{
		foreach (var spot in hotspots)
			spot.destroy ();

		hotspots.clear ();
	}

	/*
	 *  Add ctn as a new tab on nb.
	 */
	public void insert (PanelContainer ctn, Notebook nb)
	{
		if (ctn.parent == nb)
			return;

		close (ctn);

		ctn.visible = true;
		nb.append_page (ctn, ctn.get_title ());
		nb.page = nb.get_n_pages ()-1;

		if (loading)
			return;

		var key = @"panel_positions.$(ctn.type_id)";
		Preferences.instance.set_string (@"$key.notebook", nb.guid);

		var split = nb.parent as Paned;
		if (split == null)
		{
			Preferences.instance.delete_key (@"$key.sibling");
			Preferences.instance.delete_key (@"$key.orientation");
			Preferences.instance.delete_key (@"$key.first");
		} else
		{
			var first = split.get_child1 () == nb;
			var sibling =  first ? split.get_child2 () : split.get_child1 ();
			Preferences.instance.set_string (@"$key.sibling", (sibling as Notebook).guid);
			Preferences.instance.set_string (@"$key.orientation", split.orientation.to_string ());
			Preferences.instance.set_boolean (@"$key.first", first);
		}
	}

	/*
	 *  Remove ctn from its parent and remove all empty parents.
	 */
	public void close (PanelContainer ctn)
	{
		// Remove container from its parent
		var parent = ctn.parent;

		if (parent == null)
			return;

		parent.remove (ctn);

		// Remove all empty parents
		while (parent.get_children ().length () == 0)
		{
			var win = parent as Window;
			if (win != null)
			{
				win.destroy ();
				break;
			}

			var temp = parent.parent;
			temp.remove (parent);
			parent = temp;
		}
	}

	/*
	 *  Open ctn in new window.
	 */
	public void window (PanelContainer ctn)
	{
		close (ctn);

		var win = new Window (app);
		windows.add (win);
		win.destroy.connect (() =>
		{
			if (win.get_child () != null)
				serialize ();
			windows.remove (win);
		});
		var nb = new Notebook ();
		win.add (nb);
		insert (ctn, nb);
		win.show ();
	}

	/*
	 *  Split nb's space in direction facing. If first is true ctn will be first child.
	 */
	public Notebook split (PanelContainer ctn, Notebook nb, Orientation facing, bool first)
	{
		if (ctn.parent == nb)
			return nb;

		// New notebook
		var new_nb = new Notebook ();
		register_notebook (new_nb);

		// Insert Paned as parent of notebook
		var parent = nb.parent;
		parent.remove (nb);
		var pane = new Paned (facing);
		pane.visible = true;
		new_nb.visible = true;
		parent.add (pane);

		// Add both notebooks
		if (first)
		{
			pane.add1 (new_nb);
			pane.add2 (nb);
		} else
		{
			pane.add1 (nb);
			pane.add2 (new_nb);
		}

		insert (ctn, new_nb);
		pane.position = pane.max_position/2;

		return new_nb;
	}

	public void drop (int x, int y, PanelContainer ctn)
	{
		foreach (var spot in hotspots)
		{
			if (!spot.contains (x, y))
				continue;

			spot.drop (ctn);
			return;
		}

		window (ctn);
	}

	public void guess_placement (PanelContainer ctn)
	{
		var key = @"panel_positions.$(ctn.type_id)";
		var guid = Preferences.instance.get_string (@"$key.notebook");
		var nb = notebooks[guid];
		if (nb != null)
		{
			insert (ctn, nb);
			return;
		}

		var sibling = Preferences.instance.get_string (@"$key.sibling");
		nb = notebooks[sibling];
		if (nb != null)
		{
			var first = Preferences.instance.get_boolean (@"$key.first");
			var orientation = Preferences.instance.get_string (@"$key.orientation");
			var enum = orientation == "GTK_ORIENTATION_HORIZONTAL" ? Orientation.HORIZONTAL : Orientation.VERTICAL;
			nb = split (ctn, nb, enum, first);
			nb.guid = guid;
		}
		else
			window (ctn);
	}

	/*
	 *  Create container for panel and add handle buttons.
	 */
	public void open_panel (libsplat.Panel panel)
	{
		var ctn = new PanelContainer (panel);

		// Drag button
		var handle = new Button.from_icon_name ("view-grid-symbolic", IconSize.BUTTON);
		handle.button_press_event.connect ((e) =>
		{
			show_hotspots ();
			return false;
		});
		handle.button_release_event.connect ((e) =>
		{
			drop ((int) e.x_root, (int) e.y_root, ctn);
			hide_hotspots ();
			return false;
		});
		handle.visible = true;
		ctn.add_handle (handle);

		// Pop button
		var pop = new Button.from_icon_name ("go-up-symbolic", IconSize.BUTTON);
		pop.clicked.connect ((e) => window (ctn));
		pop.visible = true;
		ctn.add_handle (pop);

		// close button
		var close = new Button.from_icon_name ("window-close-symbolic", IconSize.BUTTON);
		close.clicked.connect ((e) => this.close (ctn));
		close.visible = true;
		ctn.add_handle (close);

		if (loading)
			insert (ctn, last);
		else
			guess_placement (ctn);
	}
}
