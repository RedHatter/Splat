/*************************************************************************
 *  CoreAPI.java
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
package com.digitaltea.splat.core;

import com.digitaltea.splat.core.coreplugin.TabbedEditor;
import com.digitaltea.splat.plugins.PluginAction;
import com.digitaltea.splat.plugins.SplatAPI;

import net.xeoh.plugins.base.Plugin;

import org.eclipse.swt.widgets.Shell;

import java.util.Collection;

public interface CoreAPI extends Plugin
{
	public boolean init();

	public TabbedEditor getTabbedEditor();

	public Shell getShell();

	public SplatAPI getPlugin(String id);

	public void shutdown();
}
