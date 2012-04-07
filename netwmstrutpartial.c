#include "ruby.h"
#include "rbgobject.h"
#include <gdk/gdk.h>

void Init_netwmstrutpartial(void);

VALUE set_net_wm_strut_partial(VALUE self, VALUE win, VALUE left, VALUE right, VALUE top, VALUE bottom, VALUE left_start_y, VALUE left_end_y, VALUE right_start_y, VALUE right_end_y, VALUE top_start_x, VALUE top_end_x, VALUE bottom_start_x, VALUE bottom_end_x);

VALUE set_net_wm_strut_partial(VALUE self, VALUE win, VALUE left, VALUE right, VALUE top, VALUE bottom, VALUE left_start_y, VALUE left_end_y, VALUE right_start_y, VALUE right_end_y, VALUE top_start_x, VALUE top_end_x, VALUE bottom_start_x, VALUE bottom_end_x)
{
	unsigned int params[12];

	params[0] = NUM2INT(left);
	params[1] = NUM2INT(right);
	params[2] = NUM2INT(top);
	params[3] = NUM2INT(bottom);
	params[4] = NUM2INT(left_start_y);
	params[5] = NUM2INT(left_end_y);
	params[6] = NUM2INT(right_start_y);
	params[7] = NUM2INT(right_end_y);
	params[8] = NUM2INT(top_start_x);
	params[9] = NUM2INT(top_end_x);
	params[10] = NUM2INT(bottom_start_x);
	params[11] = NUM2INT(bottom_end_x);

	GdkAtom property = gdk_atom_intern("_NET_WM_STRUT_PARTIAL", TRUE);
	GdkAtom ntype = gdk_atom_intern("CARDINAL", TRUE);

	gdk_property_change(GDK_WINDOW(RVAL2GOBJ(win)), property, ntype, 32, GDK_PROP_MODE_REPLACE, (const guchar *)params, 12);

	return self;
}

void Init_netwmstrutpartial(void)
{
	VALUE module;

	module = rb_define_module("NetWmStrutPartial");

	rb_define_module_function(module, "set", set_net_wm_strut_partial, 13);
}
