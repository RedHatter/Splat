/* document.vapi generated by valac 0.27.1, do not modify. */

[CCode (cheader_filename = "document.h")]
public class DocumentPlugin : GLib.Object {
	public DocumentPlugin ();
	public string? active (string[] args);
	public string? contents (string[] args);
	public string? @delete (string[] args);
	public string? get_id_by_index (int index);
	public Gtk.TextView get_view (string id);
	public void init ();
	public string? insert (string[] args);
	public string? new_view (string[] args);
	public string? rename (string[] args);
	public void set_active (string id);
	public string active_id { get; private set; }
}
[CCode (cheader_filename = "document.h")]
public class Gutter : Gtk.Label {
	public Gutter (Gtk.TextView doc);
	public void calc_width ();
	public Pango.Color active_color { get; set; }
	public int cursor { get; private set; }
	public Gtk.TextView doc { get; construct; }
	public int line_count { get; set; }
}
