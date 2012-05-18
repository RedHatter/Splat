/*************************************************************************
 *  BasicEdits.java
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
package com.digitaltea.splat.plugins.basicedits;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;

import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

import java.util.Collection;
import java.util.ArrayList;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;

@PluginImplementation
public class BasicEdits implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	@Init
	public boolean init()
	{
		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		actions.add(new ActionAdapter() {
			public void execute()
			{
				core.getTabbedEditor().getEditor().cut();
			}
			public String getId()
			{
				return "basicedits_cut";
			}
		});
		actions.add(new ActionAdapter() {
			public void execute()
			{
				core.getTabbedEditor().getEditor().copy();
			}
			public String getId()
			{
				return "basicedits_copy";
			}
		});
		actions.add(new ActionAdapter() {
			public void execute()
			{
				core.getTabbedEditor().getEditor().paste();
			}
			public String getId()
			{
				return "basicedits_paste";
			}
		});
		actions.add(new ActionAdapter() {
			public void execute()
			{
				core.getTabbedEditor().getEditor().selectAll();
			}
			public String getId()
			{
				return "basicedits_select-all";
			}
		});
		return actions;
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown BasicEdits");}
}
