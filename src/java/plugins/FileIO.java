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
package com.digitaltea.splat.plugins.fileio;

import com.digitaltea.splat.plugins.*;
import com.digitaltea.splat.core.CoreAPI;
import com.digitaltea.splat.core.coreplugin.DocumentTab;
import com.digitaltea.splat.core.coreplugin.TabbedEditor;

//Loaded from plugin framework library (jspf), needed to imlement plugin
import net.xeoh.plugins.base.annotations.PluginImplementation;
import net.xeoh.plugins.base.annotations.events.*;
import net.xeoh.plugins.base.annotations.injections.InjectPlugin;

import java.util.Collection;
import java.util.ArrayList;
import java.lang.StringBuilder;
import java.io.File;
import java.io.Reader;
import java.io.Writer;
import java.io.BufferedWriter;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;


import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.SWT;

@PluginImplementation
public class FileIO implements SplatAPI
{

	@InjectPlugin
	public CoreAPI core;

	private Shell shell;

	@Init
	public boolean init()
	{
		shell = core.getShell();

		shell.addListener (SWT.Close, new Listener ()
		{
			public void handleEvent (Event e)
			{
				TabbedEditor tabFolder = core.getTabbedEditor();
				DocumentTab[] editors = tabFolder.getEditors();

				for (DocumentTab editor : editors)
				{
					if (!editor.getSavedState())
					{
						MessageBox alert = new MessageBox(shell, SWT.CANCEL|SWT.NO|SWT.YES);
	//					alert.setText("");
						alert.setMessage("Save Changes to \"" + editor.getName() + "\" before closing?");

						switch (alert.open())
						{
							case SWT.YES:
								save(editor);
							break;
							case SWT.CANCEL:
								e.doit = false;
							break;
						}

					} else
					{
						tabFolder.closeTab();
					}
				}
			}
		});
		return true;
	}

	public Collection<PluginAction> getActions()
	{
		Collection<PluginAction> actions = new ArrayList<PluginAction>();
		actions.add(new PluginAction()
		{
			public void execute()
			{
				core.getTabbedEditor().newTab();
			}
			public String getId()
			{
				return "fileio_new";
			}
		});
		actions.add(new PluginAction()
		{
			public void execute()
			{
				//TODO Add support for diffrent encodings
				File file = showFileDialog(shell, SWT.OPEN);
				if (file.getName() != "")
				{
					String content = "";
					try {
						Reader reader = new BufferedReader(new FileReader(file));
						StringBuilder builder = new StringBuilder();
						char[] buffer = new char[8192];
						int read;
						while ((read = reader.read(buffer, 0, buffer.length)) > 0) {
							builder.append(buffer, 0, read);
						}				
						content = builder.toString();
						reader.close();
					}
					catch (IOException e)
					{
						System.err.println("Caught IOException: " + e.getMessage());
					}
					core.getTabbedEditor().newTab(file, content);
					core.getTabbedEditor().getEditor().setSavedState(true);
				}
			}
			public String getId()
			{
				return "fileio_open";
			}
		});
		actions.add(new PluginAction()
		{
			public void execute()
			{
				save(core.getTabbedEditor().getEditor());
			}
			public String getId()
			{
				return "fileio_save";
			}
		});
		actions.add(new PluginAction()
		{
			public void execute()
			{
				File file = showFileDialog(shell, SWT.SAVE);
				if (file.getName() != "")
				{
					DocumentTab editor = core.getTabbedEditor().getEditor();
					String content = editor.getText();
					writeToFile(file, content);
					editor.setSavedState(true);
				}
			}
			public String getId()
			{
				return "fileio_save-as";
			}
		});
		actions.add(new PluginAction()
		{
			public void execute()
			{
				TabbedEditor tabFolder = core.getTabbedEditor();
				DocumentTab editor = tabFolder.getEditor();

				if (!editor.getSavedState())
				{
					MessageBox alert = new MessageBox(shell, SWT.CANCEL|SWT.NO|SWT.YES);
//					alert.setText("");
					alert.setMessage("Save Changes to \"" + editor.getName() + "\" before closing?");

					switch (alert.open())
					{
						case SWT.YES:
							save(editor);
						break;
						case SWT.NO:
							tabFolder.closeTab();
						break;
					}

				} else
				{
					tabFolder.closeTab();
				}
			}
			public String getId()
			{
				return "fileio_close";
			}
		});
		actions.add(new PluginAction()
		{
			public void execute()
			{
				core.getShell().close();
			}
			public String getId()
			{
				return "fileio_quit";
			}
		});
		return actions;
	}

	private void save(DocumentTab editor)
	{
		String content = editor.getText();
		File file = editor.getFile();
		if (file == null)
			file = showFileDialog(shell, SWT.SAVE);

		if (file.getName() != "")
		{
			writeToFile(file, content);
			editor.setSavedState(true);
		}

	}

	private File showFileDialog(Shell parent, int style)
	{
		FileDialog dialog = new FileDialog(parent, style);
		dialog.setOverwrite(true);

		String filterPath = "/";
		String platform = SWT.getPlatform();
		if (platform.equals("win32") || platform.equals("wpf"))
			filterPath = "c:\\";

		dialog.setFilterPath(filterPath);
		String location = dialog.open();
		if (location != null)
			return new File(location);
		else
			return new File("");

	}

	private void writeToFile(File file, String content)
	{
		try
		{
			Writer writer = new BufferedWriter(new FileWriter(file));
			writer.write(content);
			writer.close();
		}
		catch (IOException e)
		{
			System.err.println("Caught IOException: " + e.getMessage());
		}
	}

	@Shutdown
	public void shutdown() {System.out.println("Shutdown FileIO");}
}
