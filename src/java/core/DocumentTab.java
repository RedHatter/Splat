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
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.custom.LineStyleListener;
import org.eclipse.swt.custom.LineStyleEvent;
import org.eclipse.swt.custom.Bullet;
import org.eclipse.swt.custom.ST;
import org.eclipse.swt.custom.StyleRange;
import org.eclipse.swt.graphics.GlyphMetrics;

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
	final private String FONT = "Ubuntu Mono";

	public DocumentTab(TabFolder parent, File locationArg)
	{
		super(parent, SWT.MULTI|SWT.V_SCROLL|SWT.H_SCROLL|SWT.WRAP);

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

		setFont(new Font(parent.getDisplay(), FONT, 13, SWT.NORMAL));

		addModifyListener(new ModifyListener()
		{
			public void modifyText(ModifyEvent e)
			{
				setSavedState(false);
			}
		});

		addLineStyleListener(new LineStyleListener()
		{
			public void lineGetStyle(LineStyleEvent e)
			{
				e.bulletIndex = getLineAtOffset(e.lineOffset);
				StyleRange style = new StyleRange();
				style.metrics = new GlyphMetrics(0, 0, Integer.toString(getLineCount()+1).length()*12);
				e.bullet = new Bullet(ST.BULLET_NUMBER,style);
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

	private static int numLen(int n)
	{
        int l;
        n=Math.abs(n);
        for (l=0;n>0;++l)
                n/=10;
        return l;
	}

}
