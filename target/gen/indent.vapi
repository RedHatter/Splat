/* indent.vapi generated by valac 0.27.1, do not modify. */

[CCode (cheader_filename = "indent.h")]
public class IndentPlugin : GLib.Object {
	public IndentPlugin ();
	public void init ();
	public string? set_size (string[] args);
	public string? set_spaces (string[] args);
}
[CCode (cheader_filename = "indent.h")]
public class Indent : GLib.Object {
	public Indent (Gtk.TextView doc);
	public void set_size (int size);
	public void set_spaces (bool enabled);
}
[CCode (cheader_filename = "indent.h")]
public class Tabs : GLib.Object {
	public Gtk.TextView doc;
	public int size;
	public bool tabs;
	public Tabs ();
}
