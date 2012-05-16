/*************************************************************************
 *  UndoManager.java
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
package com.digitaltea.splat.plugins.undomanager;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;
import com.digitaltea.splat.core.coreplugin.NewTabListener;
import com.digitaltea.splat.core.coreplugin.NewTabEvent;
import com.digitaltea.splat.core.coreplugin.DocumentTab;

import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

import java.util.List;
import java.util.Collection;
import java.util.ArrayList;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;

@PluginImplementation
public class UndoManager implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	private List<UndoHandler> undoHandlers = new ArrayList<UndoHandler>();

	@Init
	public boolean init()
	{
		undoHandlers.add(new UndoHandler(core.getTabbedEditor().getEditor()));
		core.getTabbedEditor().addNewTabListener(new NewTabListener()
		{
			public void newTab(NewTabEvent e)
			{
				undoHandlers.add(new UndoHandler(e.editor));
			}
		});

		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		actions.add(new PluginAction() {
			public void execute()
			{
				getHandler().undo();
			}
			public String getId()
			{
				return "undomanager_undo";
			}
		});
		actions.add(new PluginAction() {
			public void execute()
			{
				getHandler().redo();
			}
			public String getId()
			{
				return "undomanager_redo";
			}
		});
		return actions;
	}

	private UndoHandler getHandler()
	{
		DocumentTab editor = core.getTabbedEditor().getEditor();

		for (int i = 0; i < undoHandlers.size(); i++)
		{
			if (undoHandlers.get(i).getEditor() == editor)
			{
				return undoHandlers.get(i);
			}
		}

		return null;
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown UndoManager");}
}
