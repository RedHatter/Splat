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

def convert (input_file, output_file):
    if input_file.endswith('json'):
        converted = "plist"
        converted_dict = json.load(open(input_file))
        plistlib.writePlist(converted_dict, output_file)
    elif input_file.endswith('plist'):
        converted = "json"
        converted_dict = plistlib.readPlist(input_file)
        converted_string = json.dumps(converted_dict, sort_keys=True, indent=4)
        open(output_file, 'w').write(converted_string)
    else:
        print("WHAT THE F*** ARE YOU TRYING TO DO??????")
        sys.exit(1)

if len(sys.argv) > 1:
    for arg in sys.argv[1:]:
        print "Converting "+arg
        convert (arg, arg[0:arg.find(".")]+".json")
else:
    file_to_open = dialog (True, "Select an existing plist or json file to convert.")
    file_to_write = dialog (False, "Select a filename to save the converted file.")
    converted = None
    convert (file_to_open, file_to_write)
