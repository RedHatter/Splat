/*************************************************************************
 *  Highlight.java
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
package com.digitaltea.splat.plugins.highlighting;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;
import com.digitaltea.splat.core.coreplugin.NewTabListener;
import com.digitaltea.splat.core.coreplugin.NewTabEvent;
import com.digitaltea.splat.core.coreplugin.DocumentTab;

import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

//Needed for syntax hilighting
import net.sf.colorer.ParserFactory;
import net.sf.colorer.swt.TextColorer;
import net.sf.colorer.swt.ColorManager;

import java.io.File;
import java.util.List;
import java.util.Collection;
import java.util.ArrayList;

@PluginImplementation
public class Highlighting implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	private TextColorer colorer;

	@Init
	public boolean init()
	{
		attach(core.getTabbedEditor().getEditor());
		core.getTabbedEditor().addNewTabListener(new NewTabListener()
		{
			public void newTab(NewTabEvent e)
			{
				attach(core.getTabbedEditor().getEditor());
			}
		});

		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		return actions;
	}

	private void attach(DocumentTab editor)
	{
			//Setup syntax highlighting
			colorer = new TextColorer(new ParserFactory(Thread.currentThread().getContextClassLoader().getResource("colorer/catalog.xml").getPath()), new ColorManager());
			colorer.attach(editor);
			colorer.setCross(true, true);
			colorer.setRegionMapper("default", true);

			File location = core.getTabbedEditor().getEditor().getFile();

			if (location != null)
				colorer.chooseFileType(location.getName());
	}

	public void setType(String type)
	{
		colorer.chooseFileType(type);
	}

	public TextColorer getColorer()
	{
		return colorer;
	}

	public String getId()
	{
		return "highlighting";
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown Highlight");}
}
