/* syntax.h generated by valac 0.27.1, the Vala compiler, do not modify */


#ifndef __GEN_SYNTAX_H__
#define __GEN_SYNTAX_H__

#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <json-glib/json-glib.h>
#include <gee.h>
#include <libsplat.h>

G_BEGIN_DECLS


#define TYPE_RANGES (ranges_get_type ())
#define RANGES(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_RANGES, Ranges))
#define RANGES_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_RANGES, RangesClass))
#define IS_RANGES(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_RANGES))
#define IS_RANGES_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_RANGES))
#define RANGES_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_RANGES, RangesClass))

typedef struct _Ranges Ranges;
typedef struct _RangesClass RangesClass;
typedef struct _RangesPrivate RangesPrivate;

#define TYPE_SYNTAX_PLUGIN (syntax_plugin_get_type ())
#define SYNTAX_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_SYNTAX_PLUGIN, SyntaxPlugin))
#define SYNTAX_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_SYNTAX_PLUGIN, SyntaxPluginClass))
#define IS_SYNTAX_PLUGIN(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_SYNTAX_PLUGIN))
#define IS_SYNTAX_PLUGIN_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_SYNTAX_PLUGIN))
#define SYNTAX_PLUGIN_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_SYNTAX_PLUGIN, SyntaxPluginClass))

typedef struct _SyntaxPlugin SyntaxPlugin;
typedef struct _SyntaxPluginClass SyntaxPluginClass;
typedef struct _SyntaxPluginPrivate SyntaxPluginPrivate;

struct _Ranges {
	GObject parent_instance;
	RangesPrivate * priv;
};

struct _RangesClass {
	GObjectClass parent_class;
};

struct _SyntaxPlugin {
	GObject parent_instance;
	SyntaxPluginPrivate * priv;
};

struct _SyntaxPluginClass {
	GObjectClass parent_class;
};


GType ranges_get_type (void) G_GNUC_CONST;
Ranges* ranges_new (void);
Ranges* ranges_construct (GType object_type);
gboolean ranges_contains (Ranges* self, gint start, gint end);
void ranges_add (Ranges* self, gint start, gint end);
GType syntax_plugin_get_type (void) G_GNUC_CONST;
void syntax_plugin_init (SyntaxPlugin* self);
gchar* syntax_plugin_set_theme (SyntaxPlugin* self, gchar** args, int args_length1);
gchar* syntax_plugin_set_lang (SyntaxPlugin* self, gchar** args, int args_length1);
JsonParser* syntax_plugin_match_lang (SyntaxPlugin* self, const gchar* file);
GeeArrayList* syntax_plugin_load_themes (SyntaxPlugin* self, GError** error);
GeeList* syntax_plugin_load_langs (SyntaxPlugin* self, GError** error);
void syntax_plugin_translate_theme (SyntaxPlugin* self, JsonParser* file, JsonParser* theme);
void syntax_plugin_set_key (SyntaxPlugin* self, const gchar* key, JsonObject* key_value, JsonParser* theme);
SyntaxPlugin* syntax_plugin_new (void);
SyntaxPlugin* syntax_plugin_construct (GType object_type);


G_END_DECLS

#endif
