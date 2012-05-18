/*************************************************************************
 *  ActionAdapter.java
 *  This file is part of Splat.
 *
 *  Copyright (C) 2012 Christian Johnson
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
package com.digitaltea.splat.plugins;

import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.MenuItem;

import java.util.Collection;
import java.util.ArrayList;

public class ActionAdapter implements PluginAction
{
	private Collection<Item> items = new ArrayList<Item>();
	private boolean enabled = true;

	public void execute()
	{
		return;
	}

	public String getId()
	{
		return "placeholder";
	}

	public void setEnabled(boolean enabled)
	{
		for (Item item : items)
		{
			((MenuItem)item).setEnabled(enabled);
		}
		this.enabled = enabled;
	}

	public void addItem(Item item)
	{
		items.add(item);
		if (!enabled)
			((MenuItem)item).setEnabled(enabled);
	}
}
