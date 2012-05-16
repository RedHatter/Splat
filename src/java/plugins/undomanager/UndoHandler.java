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

import java.util.Deque;
import java.util.ArrayDeque;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.custom.ExtendedModifyEvent;
import org.eclipse.swt.custom.ExtendedModifyListener;

public class UndoHandler
{
	private DocumentTab editor;
	private Deque<ExtendedModifyEvent> undoStack = new ArrayDeque<ExtendedModifyEvent>();
	private Deque<ExtendedModifyEvent> redoStack = new ArrayDeque<ExtendedModifyEvent>();

	private boolean lock;

	public UndoHandler(DocumentTab editor)
	{
		this.editor = editor;
		lock = false;

		editor.addExtendedModifyListener(new ExtendedModifyListener()
		{
			public void modifyText(ExtendedModifyEvent e)
			{
				if (!lock)
					undoStack.addFirst(e);
				else
					redoStack.addFirst(e);
			}
		});
	}

	public void undo()
	{
		if (!undoStack.isEmpty())
		{
			lock = true;
			ExtendedModifyEvent edit = undoStack.removeFirst();
			editor.replaceTextRange(edit.start, edit.length, edit.replacedText);
			editor.setCaretOffset(edit.start);
			lock = false;
		}
	}

	public void redo()
	{
		if (!redoStack.isEmpty())
		{
			ExtendedModifyEvent edit = redoStack.removeFirst();
			editor.replaceTextRange(edit.start, edit.length, edit.replacedText);
			editor.setCaretOffset(edit.start);
		}
	}

	public DocumentTab getEditor()
	{
		return editor;
	}
}
