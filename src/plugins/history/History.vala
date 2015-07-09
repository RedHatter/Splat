/*************************************************************************
 *  History.vala
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

public class History : GLib.Object
{
	Gee.LinkedList<Action> stack;
	int head = 0;
	bool undo_lock = false;
	string merge_pattern = " .\n";
	public Gtk.TreeStore model { get; private set; }

	public History (Gtk.TextView doc)
	{
		stack = new Gee.LinkedList<Action> ();
		var buffer = doc.buffer;
		model = new Gtk.TreeStore (2, typeof(Action), typeof (bool));

		Group group = null;
		buffer.begin_user_action.connect (() =>
		{
			group = new Group ();
		});
		buffer.end_user_action.connect (() =>
		{
			if (group.size == 1)
			{
				var action = group[0];
				if (!mergable (action) || stack.is_empty || !stack[head].merge (action))
					push (action);
				else
				{
					Gtk.TreeIter iter;
					var path = new Gtk.TreePath.from_indices (head);
					model.get_iter (out iter, path);
					model.row_changed (path, iter);
				}
			} else if (group.size > 1)
				push (group);
	
			group = null;
		});

		buffer.insert_text.connect ((ref pos, text, length) =>
		{
			if (undo_lock)
				return;

			var action = new Insert (buffer, pos.get_offset (), pos.get_offset () + length, text);
			if (group != null)
				group.add (action);
		});
		buffer.delete_range.connect ((start, end) =>
		{
			if (undo_lock)
				return;

			var text = buffer.get_text (start, end, true);
			var action = new Delete (buffer, start.get_offset (), end.get_offset (), text);
			if (group != null)
				group.add (action);
		});
	}

	private bool mergable (Action action)
	{
		return action.text.length == 1 && merge_pattern.index_of (action.text) == -1;
	}

	private void push (Action action)
	{
		Gtk.TreeIter iter;
		if (head != 0)
		{
			while (--head >= 0)
			{
				stack.remove_at (head);
				model.get_iter (out iter, new Gtk.TreePath.from_indices (head));
				model.remove (ref iter);
			}
			head = 0;
		}

		if (stack.size > 0)
			stack.insert (head, action);
		else
			stack.add (action);
		model.insert_with_values (out iter, null, head, 0, action, 1, true);

		var group = action as Group;
		if (group != null)
			foreach (var child in group)
				model.insert_with_values (null, iter, 0, 0, child, 1, true);
	}

	private Action down ()
	{
		Gtk.TreeIter iter;
		var path = new Gtk.TreePath.from_indices (head);
		model.get_iter (out iter, path);
		model.set (iter, 1, false);
		model.row_changed (path, iter);

		return stack[head++];
	}

	private Action up ()
	{
		Gtk.TreeIter iter;
		var path = new Gtk.TreePath.from_indices (--head);
		model.get_iter (out iter, path);
		model.set (iter, 1, true);
		model.row_changed (path, iter);

		return stack[head];
	}

	public void undo ()
	{
		if (stack.is_empty || head == stack.size-1)
			return;

		undo_lock = true;

		var action = down ();
		action.undo ();

		undo_lock = false;
	}

	public void redo ()
	{
		if (stack.is_empty || head == 0)
			return;

		undo_lock = true;

		var action = up ();
		action.redo ();

		undo_lock = false;
	}

	public void undo_to (Action action)
	{
		while (stack[head] != action)
			undo ();
	}

	public void redo_to (Action action)
	{
		while (stack[head] != action)
			redo ();
	}
}
