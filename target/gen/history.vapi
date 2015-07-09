/* history.vapi generated by valac 0.27.1, do not modify. */

[CCode (cheader_filename = "history.h")]
public class Delete : Action, GLib.Object {
	public Delete (Gtk.TextBuffer buffer, int start, int end, string text);
}
[CCode (cheader_filename = "history.h")]
public class Group : Action, GLib.Object {
	public Group ();
	public void add (Action action);
	public new Action @get (int i);
	public int size { get; }
}
[CCode (cheader_filename = "history.h")]
public class HistoryPlugin : GLib.Object {
	public HistoryPlugin ();
	public void init ();
	public string? redo (string[] args);
	public string? toggle_panel (string[] args);
	public string? undo (string[] args);
}
[CCode (cheader_filename = "history.h")]
public class History : GLib.Object {
	public History (Gtk.TextView doc);
	public void redo ();
	public void redo_to (Action action);
	public void undo ();
	public void undo_to (Action action);
	public Gtk.TreeStore model { get; private set; }
}
[CCode (cheader_filename = "history.h")]
public class Insert : Action, GLib.Object {
	public Insert (Gtk.TextBuffer buffer, int start, int end, string text);
	public Action reverse ();
}
[CCode (cheader_filename = "history.h")]
public interface Action : GLib.Object {
	public abstract bool merge (Action action);
	public abstract void redo ();
	public abstract string render ();
	public abstract void undo ();
	public abstract int end { get; set; }
	public abstract int start { get; set; }
	public abstract string text { get; set; }
}
