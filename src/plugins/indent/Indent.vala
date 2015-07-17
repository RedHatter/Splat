public class Indent : Object
{
	Gtk.TextView doc;
	int size;
	ulong handle;

	public Indent (Gtk.TextView doc)
	{
		this.doc = doc;
	}

	public void set_spaces (bool enabled)
	{
		if (enabled)
		{
			if (handle == -1)
				return;

			handle = doc.buffer.insert_text.connect_after ((ref pos, text, length) =>
			{
				if (text == "\t")
				{
					var end = pos;
					pos.backward_char ();
					var offset = pos.get_offset ();
					doc.buffer.delete_range (pos, end);
					doc.buffer.get_iter_at_offset (out pos, offset);
					doc.buffer.insert_text (ref pos, string.nfill (size, ' '), size);
				}
			});
		} else
		{
			doc.buffer.disconnect (handle);
			handle = -1;
		}
	}

	public void set_size (int size)
	{
		this.size = size;
		var array = new Pango.TabArray (1, true);
		array.set_tab (0, Pango.TabAlign.LEFT, calculate_tab_size (size));
		doc.tabs = array;
	}

	int calculate_tab_size (int spaces)
	{
		Pango.Layout layout;
		int tab_width = 0;
		layout = doc.create_pango_layout (string.nfill (spaces, ' '));
		if (layout != null)
			layout.get_pixel_size (out tab_width, null);

		return tab_width;
	}

}
