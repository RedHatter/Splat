/*************************************************************************
 *  Splat.java
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
package com.digitaltea.splat;

import com.digitaltea.splat.core.CoreAPI;

//Needed for plugin framwork
import net.xeoh.plugins.base.PluginManager;
import net.xeoh.plugins.base.impl.PluginManagerFactory;

//GUI widgets
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;

import java.net.URI;
import java.net.URISyntaxException;
import java.io.File;
import java.util.Collection;

public class Splat
{
	public static void main(String [] args)
	{
		//Create PluginManger and load CorePlugin witch will inturn load all other plugins
		PluginManager pm = PluginManagerFactory.createPluginManager();
		try
		{
			pm.addPluginsFrom(Thread.currentThread().getContextClassLoader().getResource("plugins").toURI());
		}
		catch (URISyntaxException e)
		{
			System.out.println(e);
		}

		CoreAPI plugin = pm.getPlugin(CoreAPI.class);

		Shell shell = plugin.getShell();
		Display display = shell.getDisplay();
		while (!shell.isDisposed())
		{
			if (!display.readAndDispatch()) display.sleep();
		}
		display.dispose();
		pm.shutdown();
	}
}
