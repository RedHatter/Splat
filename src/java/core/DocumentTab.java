/*************************************************************************
 *  DocumentTab.java
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

//GUI widgets
import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.TabItem;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.graphics.Font;

import java.net.URI;
import java.net.URISyntaxException;
import java.net.MalformedURLException;
import java.lang.ClassLoader;
import java.io.File;

public class DocumentTab extends StyledText
{
	private boolean saved;
	private File location;
	private TabItem item;

	//Default font used for setFont in constructor
	private String defaultFont = "Ubuntu Mono";

	public DocumentTab(TabFolder parent, File locationArg)
	{
		super(parent, SWT.MULTI | SWT.V_SCROLL | SWT.H_SCROLL);

		location = locationArg;

		item = new TabItem(parent, SWT.NONE);
		if(locationArg != null)
		{
			item.setText(location.getName());
		}
		else
			item.setText("Untitled Document");

		parent.setSelection(item);

		item.setControl(this);

		setFont(new Font(parent.getDisplay(), defaultFont, 13, SWT.NORMAL));

		addModifyListener(new ModifyListener()
		{
			public void modifyText(ModifyEvent e)
			{
				setSavedState(false);
			}
		});
	}

	public File getFile()
	{
		return location;
	}

	public String getName()
	{
		String title = item.getText();

		if (title.charAt(0) == '*')
			return title.substring(1).trim();
		else
			return title.trim();
	}

	public void setSavedState(boolean savedArg)
	{
		saved = savedArg;

		String title = item.getText();

		if (savedArg)
		{
			if (title.charAt(0) == '*')
				item.setText(title.substring(1));
		} else
		{
			if (title.charAt(0) != '*')
				item.setText("*"+title);
		}
	}

	public boolean getSavedState()
	{
		return saved;
	}

	public void setActive()
	{
		item.getParent().setSelection(item);
	}
}
