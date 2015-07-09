/*************************************************************************
 *  Group.vala
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


public class Group : Action, GLib.Object
{
	public string text { get; set; }
	public int start
	{
		get
		{
			return actions.first ().start;
		}

		set
		{
			var offset = value - start;
			foreach (var action in actions)
				action.start += offset;
		}
	}
	public int end
	{
		get
		{
			return actions.last ().end;
		}

		set
		{
			var offset = value - end;
			foreach (var action in actions)
				action.end += offset;
		}
	}
	public int size { get { return actions.size; } }

	Gee.List<Action> actions = new Gee.ArrayList<Action> ();

	public new Action get (int i)
	{
		return actions[i];
	}

	public void redo ()
	{
		for (var i = 0; i > actions.size; i++)
			actions[i].redo ();
	}

	public void undo ()
	{
		for (var i = actions.size-1; i >= 0; i--)
			actions[i].undo ();
	}

	public void add (Action action)
	{
		actions.add (action);
	}

	public bool merge (Action action)
	{
		if (!(action is Group))
			return false;

		actions.add_all ((action as Group).actions);

		return true;
	}

	public string render ()
	{
		return "Group";
	}
}
