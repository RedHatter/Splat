/*************************************************************************
 *  CorePlugin.java
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
package com.digitaltea.splat.core.coreplugin;

import com.digitaltea.splat.core.CoreAPI;
import com.digitaltea.splat.plugins.SplatAPI;
import com.digitaltea.splat.plugins.PluginAction;

//Needed for plugin framwork
import net.xeoh.plugins.base.PluginManager;
import net.xeoh.plugins.base.util.PluginManagerUtil;
import net.xeoh.plugins.base.annotations.Thread;
import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

//GUI widgets
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.layout.FillLayout;

import java.util.Collection;

@PluginImplementation
public class Core implements CoreAPI
{
	@InjectPlugin
	public PluginManager pluginManager;

	//The main text component
	private TabbedEditor tabbedEditor;

	//Main window
	private Shell shell;

	@Init
	public boolean init()
	{
		//Create window
		final Display display = new Display();
		shell = new Shell(display);
		shell.setLayout(new FillLayout());

		tabbedEditor = new TabbedEditor(shell);
		tabbedEditor.newTab();

		//Display window
		shell.open();

		return true;
	}

	//Intergation point for plugins
	public TabbedEditor getTabbedEditor()
	{
		return tabbedEditor;
	}

	public Shell getShell()
	{
		return shell;
	}

	//Load all plugins from new thread so init can return
	@Thread
	private void loadPlugins()
	{
		PluginManagerUtil pluginManagerUtil = new PluginManagerUtil(pluginManager);
		Collection<SplatAPI> plugins = pluginManagerUtil.getPlugins(SplatAPI.class);
	}

	//Nothing we need to do on shutdown at the moment
	@Shutdown
	public void shutdown() {System.out.println("Shutdown core");}
}
