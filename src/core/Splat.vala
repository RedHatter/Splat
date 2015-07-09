/*************************************************************************
 *  Splat.vala
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
 *  Main class. Creates and connects PluginManager, UIManager, and Preferences.
 */

using Gtk;
using libsplat;

public void handle_tabs (Widget child, int page_num)
{
	Notebook nb = (Notebook) child;
	nb.show_tabs = nb.get_n_pages () > 1;
	if (nb.get_n_pages () < 1)
	{
		var split = (Paned) nb.parent.parent;
		if (split.get_child1 () == nb.parent)
			split.position = split.min_position;
		else
			split.position = split.max_position;
	}
}

class Splat.App : Gtk.Application
{
	public App ()
	{
		Object(application_id: "idioticdev.splat", flags: ApplicationFlags.FLAGS_NONE);
	}

	protected override void activate ()
	{
		// var watch = (Paned) builder.get_object ("watch");
		// var fixme = (Paned) builder.get_object ("fixme");
		// var root = (Paned) builder.get_object("root");

		// Allocation last_size;
		// window.get_allocation (out last_size);
		// window.size_allocate.connect ((a) => 
		// {
		// 	root.position -= last_size.height-a.height;
		// 	fixme.position -= last_size.width-a.width;
		// 	last_size = a;
		// });

		// var last = watch.position;
		// watch.notify["position"].connect((s, p) =>
		// {
		// 	fixme.position -= watch.position - last;
		// 	last = watch.position;
		// });

		UIManager.instance.set_app (this);
		PluginManager.instance.panel_opened.connect (UIManager.instance.open_panel);
		PluginManager.instance.load_plugins ();
		PluginManager.instance.register_command ("core.quit", (args) =>
		{
			UIManager.instance.serialize ();
			Preferences.instance.write ();
			quit ();

			return null;
		});
		set_menubar (Preferences.instance.get_menu (this));

		UIManager.instance.unserialize ();
	}

	public static int main (string[] args)
	{
		App app = new App ();
		return app.run (args);
	}
}
