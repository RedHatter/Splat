/*************************************************************************
 *  UndoHandler.java
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
package com.digitaltea.splat.plugins.undomanager;

import com.digitaltea.splat.core.coreplugin.DocumentTab;
import com.digitaltea.splat.plugins.PluginAction;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.EventObject;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.custom.ExtendedModifyEvent;
import org.eclipse.swt.custom.ExtendedModifyListener;

public class UndoHandler
{
	private DocumentTab editor;
	private Deque<UndoEvent> undoStack = new ArrayDeque<UndoEvent>();
	private Deque<UndoEvent> redoStack = new ArrayDeque<UndoEvent>();
	private PluginAction undoItem;
	private PluginAction redoItem;

	private boolean lock;

	private class UndoEvent extends EventObject
	{
		int start;
		int length;
		String replacedText;
		boolean merge;

		public UndoEvent(Object source, int start, int length, String replacedText, boolean merge)
		{
			super(source);

			this.start = start;
			this.length = length;
			this.replacedText = replacedText;
			this.merge = merge;
		}
	}

	public UndoHandler(final DocumentTab editor, final PluginAction undoItem, final PluginAction redoItem)
	{
		this.editor = editor;
		this.undoItem = undoItem;
		this.redoItem = redoItem;
		lock = false;

		undoItem.setEnabled(false);
		redoItem.setEnabled(false);

		editor.addExtendedModifyListener(new ExtendedModifyListener()
		{
			public void modifyText(ExtendedModifyEvent e)
			{
				UndoEvent edit = new UndoEvent(e.getSource(), e.start, e.length, e.replacedText, false);

				if (!lock)
				{
					if (edit.length == 1 && editor.getTextRange(edit.start, 1).matches("\\w"))
					{
						edit.merge = true;

						UndoEvent prv = undoStack.peekFirst();
						if (prv != null && prv.merge && edit.start == prv.start+prv.length)
						{
							edit = prv;
							edit.length += 1;
							undoStack.removeFirst();
						}
					}
					undoStack.addFirst(edit);
					redoStack.clear();
					undoItem.setEnabled(true);
					redoItem.setEnabled(false);
				} else
				{
					redoStack.addFirst(edit);
					redoItem.setEnabled(true);
				}
			}
		});
	}

	public void undo()
	{
		if (!undoStack.isEmpty())
		{
			lock = true;
			UndoEvent edit = undoStack.removeFirst();
			editor.replaceTextRange(edit.start, edit.length, edit.replacedText);
			editor.setCaretOffset(edit.start);
			lock = false;

			if (undoStack.isEmpty())
				undoItem.setEnabled(false);
		}
	}

	public void redo()
	{
		if (!redoStack.isEmpty())
		{
			UndoEvent edit = redoStack.removeFirst();
			editor.replaceTextRange(edit.start, edit.length, edit.replacedText);
			editor.setCaretOffset(edit.start);

			if (redoStack.isEmpty())
				redoItem.setEnabled(false);
		}
	}

	public DocumentTab getEditor()
	{
		return editor;
	}
}
