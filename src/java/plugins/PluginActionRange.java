/*************************************************************************
 *  PluginActionRange.java
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

import java.util.Collection;

public interface PluginActionRange extends PluginAction
{
	public void execute(int index);

	public String getId();

	public void setEnabled(boolean enabled, int index);

	public void setName(String name, int index);

	public void addItems(Collection<Item> item);
}
