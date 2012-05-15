/*************************************************************************
 *  TabbedEditor.java
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

//Needed for syntax hilighting
import net.sf.colorer.ParserFactory;
import net.sf.colorer.swt.TextColorer;
import net.sf.colorer.swt.ColorManager;

//GUI widgets
import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.TabItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;


import java.io.File;

public class TabbedEditor
{
	private TabFolder tabFolder;
	private Menu popup;
	private TabItem prvSelection;

	public TabbedEditor(Composite parent)
        {
		tabFolder = new TabFolder(parent, SWT.BORDER);
		final Button button = new Button(tabFolder, SWT.NONE);
		button.setText("x");
		button.setBounds(parent.getSize().x-30, 5, 20, 20);
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				closeTab();
				if (tabFolder.getItemCount() == 0)
				{
					newTab();
				}
			}
		});
        }

	public void newTab() {newTab(null);}

	public void newTab(File location) {newTab(location, "");}

	public void newTab(File location, String content)
	{
		DocumentTab editor = new DocumentTab(tabFolder, location, content);
		editor.setMenu(popup);

		if (tabFolder.getItemCount() != 1)
		{
			Event event = new Event();
			event.item = tabFolder.getSelection()[0];
			tabFolder.notifyListeners(SWT.Selection, event);
		}
	}

	public void closeTab()
	{
		tabFolder.getSelection()[0].dispose();
	}

	public void setMenu(Menu menu)
	{
		popup = menu;
		TabItem[] items = tabFolder.getItems();
		for (TabItem item : items)
		{
			item.getControl().setMenu(menu);
		}
	}

	public DocumentTab getEditor()
	{
		return (DocumentTab)tabFolder.getSelection()[0].getControl();
	}

	public DocumentTab[] getEditors()
	{
		TabItem[] items = tabFolder.getItems();
		DocumentTab[] editors = new DocumentTab[items.length];
		for (int i = 0; i < items.length; i++)
		{
			editors[i] = (DocumentTab)items[i].getControl();
		}

		return editors;
	}
}
