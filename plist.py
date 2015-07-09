#!/usr/bin/env python
 
import plistlib
import json
import pygtk
import gtk
import re
import sys
 
def dialog (open, msg):
    dialog = gtk.FileChooserDialog(msg,
                                   None,
                                   gtk.FILE_CHOOSER_ACTION_OPEN if open else gtk.FILE_CHOOSER_ACTION_SAVE,
                                   (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                                    gtk.STOCK_OPEN if open else gtk.STOCK_SAVE, gtk.RESPONSE_OK))
    dialog.set_default_response(gtk.RESPONSE_OK)
    response = dialog.run()
    if response == gtk.RESPONSE_OK:
        return_val = dialog.get_filename()

    dialog.destroy()
    return return_val


file_to_open = dialog (True, "Select an existing plist or json file to convert.")
converted = None
 
if file_to_open.endswith('json'):
    converted = "plist"
    converted_dict = json.load(open(file_to_open))
    file_to_write = dialog (False, "Select a filename to save the converted file.")
    plistlib.writePlist(converted_dict, file_to_write)
elif file_to_open.endswith('plist'):
    converted = "json"
    converted_dict = plistlib.readPlist(file_to_open)
    converted_string = json.dumps(converted_dict, sort_keys=True, indent=4)
    file_to_write = dialog(False, "Select a filename to save the converted file.")
    open(file_to_write, 'w').write(converted_string)
else:
    print("WHAT THE F*** ARE YOU TRYING TO DO??????")
    sys.exit(1)
