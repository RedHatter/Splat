/*************************************************************************
 *  Search.java
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
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.SWT;

@PluginImplementation
public class Search implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	@Init
	public boolean init()
	{
		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		actions.add(new ActionAdapter() {
			public void execute()
			{
				openFindDialog();
			}
			public String getId()
			{
				return "search_find";
			}
		});

		actions.add(new ActionAdapter() {
			public void execute()
			{
				openReplaceDialog();
			}
			public String getId()
			{
				return "search_replace";
			}
		});

		actions.add(new ActionAdapter() {
			public void execute()
			{
				openGoToDialog();
			}
			public String getId()
			{
				return "search_goto";
			}
		});
		return actions;
	}

	private void openGoToDialog()
	{
		final DocumentTab editor = core.getTabbedEditor().getEditor();
		final Text line = new Text(editor, SWT.SINGLE|SWT.BORDER);
		line.setSize(100, 25);
		line.setLocation(editor.getSize().x-120, 5);
		line.addListener(SWT.DefaultSelection, new Listener() {
			public void handleEvent(Event e) 
			{
				String lineText = line.getText();
				int goToLine = Integer.parseInt(!lineText.equals("") ? lineText : "1")-1;
				int numLine = editor.getLineCount()-1;
				editor.setCaretOffset(editor.getOffsetAtLine(numLine < goToLine ? numLine : (goToLine > 0 ? goToLine : 0)));
				line.dispose();
				editor.forceFocus();
			}
		});
		line.forceFocus();
	}

	private void openFindDialog()
	{
		final Shell findDialog = new Shell(core.getShell().getDisplay(), SWT.DIALOG_TRIM);
		GridLayout layout = new GridLayout(4, true);
		layout.marginHeight = 15;
		layout.marginWidth = 15;
		findDialog.setLayout(layout);
		findDialog.setText("Find");

		new Label(findDialog, SWT.NONE).setText("Search for:");

		final Text searchText = new Text(findDialog, SWT.SINGLE|SWT.BORDER|SWT.ICON_SEARCH|SWT.ICON_CANCEL|SWT.SEARCH);
		GridData gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		gridData.horizontalSpan = 3;
		searchText.setLayoutData(gridData);

		Group group = new Group(findDialog, SWT.NONE);
		group.setText("Search mode");
		RowLayout rowLayout = new RowLayout();
                rowLayout.type = SWT.VERTICAL;
		group.setLayout(rowLayout);
		gridData = new GridData();
		gridData.horizontalSpan = 2;
		gridData.verticalSpan = 3;
		group.setLayoutData(gridData);

		Button button = new Button(group, SWT.RADIO);
		button.setText("Normal");
		button.setSelection(true);

		final Button regex = new Button(group, SWT.RADIO);
		regex.setText("Regular expression");

		final Button mCase = new Button(findDialog, SWT.CHECK);
		mCase.setText("Match case");
		gridData = new GridData();
		gridData.horizontalSpan = 2;
		mCase.setLayoutData(gridData);

		searchText.addListener(SWT.DefaultSelection, new Listener()
		{
			public void handleEvent(Event e) 
			{
				if (e.detail != SWT.ICON_CANCEL)
					find(searchText.getText(), regex.getSelection(), mCase.getSelection(), true, 1);
			}
		});

		button = new Button(findDialog, SWT.PUSH);
		button.setText("Find Next");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				find(searchText.getText(), regex.getSelection(), mCase.getSelection(), true, 1);
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
				find(searchText.getText(), regex.getSelection(), mCase.getSelection(), false, 1);
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		prevButton.setLayoutData(gridData);

		regex.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				if (mCase.isEnabled())
				{
					prevButton.setEnabled(false);
				} else
				{
					prevButton.setEnabled(true);
				}
			}
		});

		final Button CountButton = new Button(findDialog, SWT.PUSH);
		CountButton.setText("Count");
		CountButton.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				CountButton.setText(Integer.toString(count(searchText.getText(), regex.getSelection(), mCase.getSelection())));
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		CountButton.setLayoutData(gridData);

		button = new Button(findDialog, SWT.PUSH);
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

		findDialog.pack();
		findDialog.open();
	}


	private void openReplaceDialog()
	{
		final Shell replaceDialog = new Shell(core.getShell().getDisplay(), SWT.DIALOG_TRIM);
		GridLayout layout = new GridLayout(4, true);
		layout.marginHeight = 15;
		layout.marginWidth = 15;
		replaceDialog.setLayout(layout);
		replaceDialog.setText("Find and Replace");

		new Label(replaceDialog, SWT.NONE).setText("Search for:");

		final Text searchText = new Text(replaceDialog, SWT.SINGLE|SWT.BORDER|SWT.ICON_SEARCH|SWT.ICON_CANCEL|SWT.SEARCH);
		GridData gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		gridData.horizontalSpan = 3;
		searchText.setLayoutData(gridData);


		new Label(replaceDialog, SWT.NONE).setText("Replace with:");

		final Text replaceText = new Text(replaceDialog, SWT.SINGLE|SWT.BORDER|SWT.ICON_SEARCH|SWT.ICON_CANCEL|SWT.SEARCH);
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		gridData.horizontalSpan = 3;
		replaceText.setLayoutData(gridData);

		Group group = new Group(replaceDialog, SWT.NONE);
		group.setText("Search mode");
		RowLayout rowLayout = new RowLayout();
                rowLayout.type = SWT.VERTICAL;
		group.setLayout(rowLayout);
		gridData = new GridData();
		gridData.horizontalSpan = 2;
		group.setLayoutData(gridData);

		Button button = new Button(group, SWT.RADIO);
		button.setText("Normal");
		button.setSelection(true);

		final Button regex = new Button(group, SWT.RADIO);
		regex.setText("Regular expression");

		group = new Group(replaceDialog, SWT.NONE);
		group.setText("Search context");
		rowLayout = new RowLayout();
                rowLayout.type = SWT.VERTICAL;
		group.setLayout(rowLayout);
		gridData = new GridData();
		gridData.horizontalSpan = 2;
		group.setLayoutData(gridData);

		button = new Button(group, SWT.RADIO);
		button.setText("Current document");
		button.setSelection(true);

		final Button selContext = new Button(group, SWT.RADIO);
		selContext.setText("Selection");

		final Button allContext = new Button(group, SWT.RADIO);
		allContext.setText("All open documents");

		final Button mCase = new Button(replaceDialog, SWT.CHECK);
		mCase.setText("Match case");
		gridData = new GridData();
		gridData.horizontalSpan = 4;
		mCase.setLayoutData(gridData);

		button = new Button(replaceDialog, SWT.PUSH);
		button.setText("Close");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				replaceDialog.dispose();	
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		button = new Button(replaceDialog, SWT.PUSH);
		button.setText("Replace All");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				int context;
				if (selContext.getSelection() == true)
					context = 2;
				else if (allContext.getSelection() == true)
					context = 3;
				else
					context = 1;

				replaceAll(searchText.getText(), replaceText.getText(), regex.getSelection(), mCase.getSelection(), context);
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		searchText.addListener(SWT.DefaultSelection, new Listener()
		{
			public void handleEvent(Event e) 
			{
				if (e.detail != SWT.ICON_CANCEL)
				{
					int context;
					if (selContext.getSelection() == true)
						context = 2;
					else if (allContext.getSelection() == true)
						context = 3;
					else
						context = 1;

					find(searchText.getText(), regex.getSelection(), mCase.getSelection(), true, context);
				}
			}
		});

		replaceText.addListener(SWT.DefaultSelection, new Listener()
		{
			public void handleEvent(Event e) 
			{
				if (e.detail != SWT.ICON_CANCEL)
					core.getTabbedEditor().getEditor().insert(replaceText.getText());
			}
		});

		final Button prevButton = new Button(replaceDialog, SWT.PUSH);
		prevButton.setText("Replace");
		prevButton.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				core.getTabbedEditor().getEditor().insert(replaceText.getText());
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		prevButton.setLayoutData(gridData);

		button = new Button(replaceDialog, SWT.PUSH);
		button.setText("Find");
		button.addSelectionListener(new SelectionAdapter()
		{
			public void widgetSelected(SelectionEvent e)
			{
				int context;
				if (selContext.getSelection() == true)
					context = 2;
				else if (allContext.getSelection() == true)
					context = 3;
				else
					context = 1;

				find(searchText.getText(), regex.getSelection(), mCase.getSelection(), true, context);
			}
		});
		gridData = new GridData();
		gridData.horizontalAlignment = GridData.FILL;
		button.setLayoutData(gridData);

		replaceDialog.pack();
		replaceDialog.open();
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

	private void replaceAll(String searchText, String replaceText, boolean regex, boolean mCase, int context)
	{
		DocumentTab editor = core.getTabbedEditor().getEditor();
		String text = "";
		String newText = "";

		switch (context)
		{
			case 1:
				text = editor.getText();
				break;
			case 2:
				text = editor.getSelectionText();
				break;
			case 3:
				DocumentTab[] editors = core.getTabbedEditor().getEditors();
				for (DocumentTab e : editors)
				{
					e.setActive();
					replaceAll(searchText, replaceText, regex, mCase, 1);
				}

				break;
		}

		if (regex)
		{
			Matcher matcher;

			if (mCase)
				matcher = Pattern.compile(searchText).matcher(text);
			else
				matcher = Pattern.compile(searchText, Pattern.CASE_INSENSITIVE).matcher(text);

			newText = matcher.replaceAll(replaceText);
		} else
		{
			if (mCase)
				newText = text.replace(searchText, replaceText);
			else
				newText = Pattern.compile(Pattern.quote(searchText), Pattern.CASE_INSENSITIVE)
						.matcher(text)
						.replaceAll(replaceText);
		}

		switch (context)
		{
			case 1:
				if (!newText.equals(text))
					editor.setText(newText);
				break;
			case 2:
				editor.insert(newText);
				break;
		}
	}

	private int find(String search, boolean regex, boolean mCase, boolean down, int context)
	{
		DocumentTab editor = core.getTabbedEditor().getEditor();
		String text = "";
		int caret = 0;

		switch (context)
		{
			case 1: case 3:
				text = editor.getText();
				caret = editor.getCaretOffset();
				break;
			case 2:
				text = editor.getSelectionText();
				caret = 0;
				break;
		}

		int start;
		int end;

		if (regex)
		{
			Matcher matcher;

			if (mCase)
				matcher = Pattern.compile(search).matcher(text);
			else
				matcher = Pattern.compile(search, Pattern.CASE_INSENSITIVE).matcher(text);

			if (matcher.find(caret))
			{
				start = matcher.start();
				end = matcher.end();
			} else
			{
				start = -1;
				end = 0;
			}
		} else
		{

			if (!mCase)
			{
				text = text.toLowerCase();
				search = search.toLowerCase();
			}

			if (down)
			{
				start = text.indexOf(search, caret);
				end = start + search.length();
			} else
			{
				start = text.lastIndexOf(search, caret-1-search.length());
				end = start + search.length();
			}
		}
		if (start != -1)
		{
			if (context == 2)
			{
				int offset = editor.getSelectionRanges()[0];
				start += offset;
				end += offset;
			}

			editor.setSelection(start, end);
		} else if (context == 3)
		{
			editor.setCaretOffset(0);
			DocumentTab[] editors = core.getTabbedEditor().getEditors();
			for (int i = 0; i < editors.length; i++)
			{
				if (editors[i] == editor)
				{
					editors[(i+1 < editors.length) ? i+1 : 0].setActive();
					break;
				}
			}
		}

		return start;
	}

	public String getId()
	{
		return "search";
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown Search");}
}
