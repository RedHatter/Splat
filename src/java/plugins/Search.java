/*************************************************************************
 *  FileIO.java
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
package com.digitaltea.splat.plugins.search;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;
import com.digitaltea.splat.core.coreplugin.DocumentTab;

import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

import java.util.Collection;
import java.util.ArrayList;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.SWT;

@PluginImplementation
public class Search implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	private Matcher matcher;

	@Init
	public boolean init()
	{
		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		actions.add(new PluginAction() {
			public void execute()
			{
				openFindDialog();
			}
			public String getId()
			{
				return "search_find";
			}
		});
		return actions;
	}

	private void openFindDialog()
	{
		final Shell findDialog = new Shell(core.getShell().getDisplay(), SWT.DIALOG_TRIM);
		GridLayout layout = new GridLayout(4, true);
		layout.marginHeight = 15;
		layout.marginWidth = 15;
		findDialog.setLayout(layout);

		new Label(findDialog, SWT.NONE).setText("Search for:");

		final Text searchI = new Text(findDialog, SWT.SINGLE|SWT.BORDER);
		GridData gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		gridData.horizontalSpan = 3;
		searchI.setLayoutData(gridData);

		final Button regex = new Button(findDialog, SWT.CHECK);
		regex.setText("Regex");
		gridData = new GridData();
		gridData.horizontalSpan = 4;
		regex.setLayoutData(gridData);

		final Button mCase = new Button(findDialog, SWT.CHECK);
		mCase.setText("Match case");
		gridData = new GridData();
		gridData.horizontalSpan = 4;
		mCase.setLayoutData(gridData);

		Button button = new Button(findDialog, SWT.PUSH);
		button.setText("Close");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				findDialog.dispose();	
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		button = new Button(findDialog, SWT.PUSH);
		button.setText("Find Next");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				findNext(searchI.getText(), regex.getSelection(), mCase.getSelection(), true);
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		final Button prevButton = new Button(findDialog, SWT.PUSH);
		prevButton.setText("Find Previous");
		prevButton.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				findNext(searchI.getText(), regex.getSelection(), mCase.getSelection(), false);
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		prevButton.setLayoutData(gridData);

		regex.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				if (prevButton.isEnabled())
				{
					prevButton.setEnabled(false);
					mCase.setEnabled(false);
				}
				else
				{
					prevButton.setEnabled(true);
					mCase.setEnabled(true);
				}
			}
		});

		final Button CountButton = new Button(findDialog, SWT.PUSH);
		CountButton.setText("Count");
		CountButton.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				CountButton.setText(Integer.toString(count(searchI.getText(), regex.getSelection(), mCase.getSelection())));
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		CountButton.setLayoutData(gridData);

		findDialog.pack();
		findDialog.open();
	}

	private int count(String search, boolean regex, boolean mCase)
	{
		String text = core.getTabbedEditor().getEditor().getText();

		if (!mCase)
		{
			text = text.toLowerCase();
			search = search.toLowerCase();
		}

		int lastIndex = 0;
		int count = 0;

		if (regex)
		{
			Matcher matcher = Pattern.compile(search).matcher(text);
			while (matcher.find())
				count ++;
		} else
		{
			while (lastIndex != -1)
			{
				if (count == 0)
					lastIndex = text.indexOf(search);
				else
					lastIndex = text.indexOf(search, lastIndex+search.length());
				if (lastIndex != -1)
					count ++;
			}
		}
		return count;
	}

	private void findNext(String search, boolean regex, boolean mCase, boolean down)
	{
		DocumentTab editor = core.getTabbedEditor().getEditor();
		String text = editor.getText();

		if (!mCase)
		{
			text = text.toLowerCase();
			search = search.toLowerCase();
		}

		int start;
		int end;

		if (regex)
		{
			if (matcher == null || !matcher.pattern().pattern().equals(search))
				matcher = Pattern.compile(search).matcher(text);

			if (matcher.find())
			{
				start = matcher.start();
				end = matcher.end();
			} else
			{
				matcher.reset();
				findNext(search, regex, mCase, down);
				return;
			}
		} else
		{
			if (down)
			{
				start = text.indexOf(search, editor.getCaretOffset());
				end = start + search.length();
			} else
			{
				start = text.lastIndexOf(search, editor.getCaretOffset()-1-search.length());
				end = start + search.length();
			}
		}
		if (start != -1)
			editor.setSelection(start, end);
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown Search");}
}
