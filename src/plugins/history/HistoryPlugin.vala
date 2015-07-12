/*************************************************************************
 *  HistoryPlugin.vala
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
	Can't have method name do in an interface?

	TODO: Undo in selection. Selective undo. TreeView selection fallows head.
	Save/load undo stack. Use TreeSore instead of LinkedList to sore stack.
*/

using libsplat;

public class HistoryPlugin : GLib.Object
{
	DocumentPlugin _document;
	DocumentPlugin document
	{
		get
		{
			if (_document == null)
				_document = (DocumentPlugin) PluginManager.instance.get_plugin ("document");

			return _document;
		}
	}

	Gee.Map<string,History> histories;

	HistoryPanel _panel;
	HistoryPanel panel
	{
		get
		{
			if (_panel == null)
			{
				_panel = new HistoryPanel ();
				_panel.get_selection ().changed.connect ((self) =>
				{
					var history = histories[document.active_id];
					Gtk.TreeIter iter;
					if (!self.get_selected (null, out iter))
						return;

					Action action;
					bool enabled;
					history.model.get (iter, 0, out action, 1, out enabled);
					if (action == null)
						return;

					if (enabled)
						history.undo_to (action);
					else
						history.redo_to (action);
				});

				document.notify["active-id"].connect((s, p) => update_model ());
				update_model ();
			}

			return _panel;
		}
	}

	public void init ()
	{
		histories = new Gee.TreeMap<string,History> ();

		PluginManager.instance.register_command ("history.undo", undo);
		PluginManager.instance.register_command ("history.redo", redo);
		PluginManager.instance.register_command ("history.panel", toggle_panel);

		PluginManager.instance.command_called.connect ((command, result, args) =>
		{
			if (command == "document.new" && histories[result] == null)
			{
				histories[result] = (new History (document.get_view (result)));
				update_model ();
			}
		});
	}

	private void update_model ()
	{
		if (panel != null && histories.has_key (document.active_id))
			panel.model = histories[document.active_id].model;
	}

	public string? toggle_panel (string[] args)
	{
		if (panel.parent != null)
			panel.parent.remove (panel);

		panel.visible = true;
		PluginManager.instance.open_panel (panel);
		return null;
	}

	public string? undo (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		histories[id].undo ();

		return null;
	}

	public string? redo (string[] args)
	{
		var id = args[0];
		if (id == null)
			return null;

		histories[id].redo ();

		return null;
	}
}
