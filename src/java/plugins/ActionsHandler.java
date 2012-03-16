/*************************************************************************
 *  ActionsHandlerPlugin.java
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
package com.digitaltea.splat.plugins.actionshandler;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;

import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

//For loading xml
import xmlwise.XmlElement;
import xmlwise.Xmlwise;
import xmlwise.XmlParseException;


import java.util.Collection;
import java.util.ArrayList;
import java.util.ListIterator;
import java.io.IOException;

//Widgets need, mostly menu related
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.SWT;

//TODO GUI manager, error handeling

@PluginImplementation
public class ActionsHandler implements SplatAPI
{
	//Main plugin entery point
	@InjectPlugin
	public CoreAPI core;

	//Not used, but could be usefull in future
	private Collection<PluginAction> actionList;

	private XmlElement xmlNodes;
	private Menu popup;

	@Init
	public boolean init()
	{
		//Initlize actionList, built in registerActions
		actionList = new ArrayList<PluginAction>();

		//Create and set menu-bar for application, and menu for popup
		final Shell shell = core.getShell();
		popup = new Menu(core.getShell(), SWT.POP_UP);
		core.getTabbedEditor().setMenu(popup);
		Menu appMenuBar = new Menu(shell, SWT.BAR);
		shell.setMenuBar(appMenuBar);

		//Load menu and actions xml
		try
		{
			xmlNodes = Xmlwise.loadXml(Thread.currentThread().getContextClassLoader().getResource("config.xml").getPath());
			XmlElement menubarNode = xmlNodes.getUnique("menubar");
			buildMenus(menubarNode, appMenuBar);
		}
		catch (XmlParseException e) {System.out.print(e);}
		catch (IOException e) {System.out.print(e);}
		return true;
	}

	//Called recusevly to build menus
	private void buildMenus(XmlElement parentNode, Menu parentMenu)
	{
		//loop through menu elements, creating menu objects and calling buildMenu for any child menus
		ListIterator menuNodes = parentNode.get("menu").listIterator();
		while(menuNodes.hasNext())
		{
			XmlElement childNode = (XmlElement)menuNodes.next();

			//Create menu object
			MenuItem menu = new MenuItem(parentMenu, SWT.CASCADE);
			menu.setText(childNode.getAttribute("name"));
			Menu dropdown = new Menu(parentMenu);
			menu.setMenu(dropdown);

			//Create separators and placeholder MenuItems that will be removed once the actions are added
			ListIterator itemNodes = childNode.get("item").listIterator();
			while(itemNodes.hasNext())
			{
				if (((XmlElement)itemNodes.next()).getAttribute("type").equals("separator"))
				{
					new MenuItem(dropdown, SWT.SEPARATOR);
				} else
				{
					new MenuItem(dropdown, SWT.PUSH);
				}
			}

			buildMenus(childNode, dropdown);
		}
	}


	//Call each time a plugin is loaded. Build list of all PluginActions, and create menu items removing placeholders.
	@PluginLoaded
	public void registerActions(SplatAPI plugin)
	{
		//Add actions to the list
		Collection<PluginAction> actions = plugin.getActions();
		actionList.addAll(actions);

		try
		{
			XmlElement actionNodes = xmlNodes.getUnique("actions");

			//Loop plugin actions, removing placeholders, creating MenuItems, and adding them to the menu.
			for (PluginAction action : actions)
			{
				XmlElement actionXml = actionNodes.getUnique(action.getId());

				//Each number separated with / is the index of the item's parent menus
				String[] position = actionXml.getUnique("menu").getValue().split("/");
				Menu dropdown = core.getShell().getMenuBar();
				for (String index : position)
				{
					//Get the last most parent menu
					dropdown = dropdown.getItem(Integer.parseInt(index)).getMenu();
				}
				//So action can be acssesed from inner class
				final PluginAction thisAction = action;

				int index =  Integer.parseInt(actionXml.getUnique("postion").getValue());

				//Remove placeholder
				dropdown.getItem(index).dispose();

				//Create the menu item
				MenuItem item = new MenuItem(dropdown, SWT.PUSH, index);
				item.setText(actionXml.getUnique("name").getValue());
				item.setAccelerator(Integer.parseInt(actionXml.getUnique("shortcut").getValue()));
				item.addSelectionListener(new SelectionAdapter()
				{
					public void widgetSelected(SelectionEvent e)
					{
						thisAction.execute();
					};
				});

				if (actionXml.contains("popup"))
				{
					MenuItem itemPop= new MenuItem(popup, SWT.PUSH);
					itemPop.setText(actionXml.getUnique("name").getValue());
					itemPop.setAccelerator(Integer.parseInt(actionXml.getUnique("shortcut").getValue()));
					itemPop.addSelectionListener(new SelectionAdapter()
					{
						public void widgetSelected(SelectionEvent e)
						{
							thisAction.execute();
						};
					});
				}
			}
		}
		catch (XmlParseException e) {System.out.print(e);}
	}

	public Collection<PluginAction> getActions()
	{
		//No actions for now
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		return actions;
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown Menubar");}
}
