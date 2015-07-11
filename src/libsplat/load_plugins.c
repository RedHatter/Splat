/*************************************************************************
 *  load_plugins.c
 *  This file is part of Splat.
 *
 *  Copyright (C) 2015 Christian Johnson
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

/*
 *  Used from the PluginManager to load the plugins. Could not access dlfcn
 *  from vala
 */

#include <stdlib.h>
#include <stdio.h>
#include <dlfcn.h>
#include <string.h> 
#include <gio/gio.h>


char* name;
void* plugin;
splat_load_plugin (char dir[], char plugin_name[])
{
	printf("Loading %s\n", plugin_name);
	name = plugin_name;

	plugin = dlopen(dir, RTLD_NOW|RTLD_NODELETE);
	if (!plugin)
	{
		fputs (dlerror(), stderr);
		exit(1);
	}
}

void* splat_create_object ()
{
	char *error;
	void (*init)(void*);
	void* (*new)();

	// Create plugin instance
	char *new_str = malloc (strlen (name) + 12);
	strcpy (new_str, name);
	strcat (new_str, "_plugin_new");
	new = dlsym(plugin, new_str);
	if ((error = dlerror()) != NULL)
	{
		fputs(error, stderr);
		exit(1);
	}
	void* object = new ();

	// Call init
	char *init_str = malloc (strlen (name) + 13);
	strcpy (init_str, name);
	strcat (init_str, "_plugin_init");
	init = dlsym(plugin, init_str);
	if ((error = dlerror()) != NULL)
	{
		fputs(error, stderr);
		exit(1);
	}
	init (object);

	return object;
}

GResource* splat_get_resource ()
{
	char *error;
	GResource* (*resource) ();
	char *resource_str = malloc (strlen (name) + 14);
	strcpy (resource_str, name);
	strcat (resource_str, "_get_resource");
	resource = dlsym(plugin, resource_str);
	free (resource_str);
	if ((error = dlerror()) != NULL)
	{
		fputs(error, stderr);
		exit(1);
	}

	return resource ();
}

splat_close_plugin ()
{
	dlclose(plugin);
}
