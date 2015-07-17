using libsplat;

public class IndentPlugin : Object
{
	Gee.Map<string, Indent> indents;

	public void init ()
	{
		indents = new Gee.HashMap<string, Indent> ();

		PluginManager.instance.register_command ("indent.set_size", set_size);
		PluginManager.instance.register_command ("indent.set_spaces", set_spaces);

		var doc = (DocumentPlugin) PluginManager.instance.get_plugin ("document");
		PluginManager.instance.command_called.connect ((command, result, args) =>
		{
			if (command == "document.new")
			{
				indents[result] = new Indent (doc.get_view (result));
				indents[result].set_size (4);
			}
		});
	}

	public string? set_size (string[] args)
	{
		var id = args[0];
		var size = args[1] == null ? -1 : int.parse (args[1]);
		if (id == null || size < 0)
			return null;

		indents[id].set_size (size);

		return null;
	}

	public string? set_spaces (string[] args)
	{
		var id = args[0];
		var enabled = args[1] != "false";
		if (id == null)
			return null;

		indents[id].set_spaces (enabled);

		return null;
	}
}
