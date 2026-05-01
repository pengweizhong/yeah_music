#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gio/gio.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* taskbar_progress_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static GDBusConnection* taskbar_progress_dbus_connection() {
  static GDBusConnection* connection = nullptr;
  if (connection != nullptr) return connection;
  g_autoptr(GError) error = nullptr;
  connection = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
  return connection;
}

static void emit_taskbar_progress_signal(bool visible, double progress) {
  auto* conn = taskbar_progress_dbus_connection();
  if (conn == nullptr) return;
  if (progress < 0.0) progress = 0.0;
  if (progress > 1.0) progress = 1.0;
  g_autofree gchar* app_uri =
      g_strdup_printf("application://%s.desktop", APPLICATION_ID);
  GVariantBuilder props_builder;
  g_variant_builder_init(&props_builder, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&props_builder, "{sv}", "progress-visible",
                        g_variant_new_boolean(visible));
  g_variant_builder_add(&props_builder, "{sv}", "progress",
                        g_variant_new_double(progress));
  g_autoptr(GError) error = nullptr;
  g_dbus_connection_emit_signal(
      conn, nullptr, "/com/canonical/Unity/LauncherEntry",
      "com.canonical.Unity.LauncherEntry", "Update",
      g_variant_new("(sa{sv})", app_uri, &props_builder), &error);
}

static void taskbar_progress_method_call_cb(FlMethodChannel* channel,
                                            FlMethodCall* method_call,
                                            gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, "setProgress") == 0) {
    bool visible = true;
    double progress = 0.0;
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* visible_val = fl_value_lookup_string(args, "visible");
      if (visible_val != nullptr &&
          fl_value_get_type(visible_val) == FL_VALUE_TYPE_BOOL) {
        visible = fl_value_get_bool(visible_val);
      }
      FlValue* progress_val = fl_value_lookup_string(args, "progress");
      if (progress_val != nullptr &&
          fl_value_get_type(progress_val) == FL_VALUE_TYPE_FLOAT) {
        progress = fl_value_get_float(progress_val);
      } else if (progress_val != nullptr &&
                 fl_value_get_type(progress_val) == FL_VALUE_TYPE_INT) {
        progress = static_cast<double>(fl_value_get_int(progress_val));
      }
    }
    emit_taskbar_progress_signal(visible, progress);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "clearProgress") == 0) {
    emit_taskbar_progress_signal(false, 0.0);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void setup_taskbar_progress_channel(MyApplication* self, FlView* view) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->taskbar_progress_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "yeah_music/linux_taskbar_progress", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->taskbar_progress_channel, taskbar_progress_method_call_cb,
      g_object_ref(self), g_object_unref);
}

static void set_window_icon_from_asset(GtkWindow* window) {
  // Prefer the bundled Flutter asset path. Try both executable-relative and
  // cwd-relative paths to cover different launch contexts.
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  g_autofree gchar* exe_dir = exe_path ? g_path_get_dirname(exe_path) : nullptr;
  g_autofree gchar* exe_relative = exe_dir
      ? g_build_filename(exe_dir, "data", "flutter_assets", "assets", "icons",
                         "yeah_music1.png", nullptr)
      : nullptr;
  g_autofree gchar* cwd_relative = g_build_filename(
      "data", "flutter_assets", "assets", "icons", "yeah_music1.png", nullptr);

  const gchar* candidates[] = {
      exe_relative,
      cwd_relative,
      "assets/icons/yeah_music1.png",
      "assets/icons/yeah_music.png",
      nullptr,
  };

  for (int i = 0; candidates[i] != nullptr; ++i) {
    const gchar* path = candidates[i];
    if (path == nullptr || !g_file_test(path, G_FILE_TEST_EXISTS)) continue;
    g_autoptr(GError) error = nullptr;
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, &error);
    if (pixbuf == nullptr) continue;
    gtk_window_set_icon(window, pixbuf);
    g_object_unref(pixbuf);
    return;
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "yeah_music");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "yeah_music");
  }

  gtk_window_set_default_size(window, 1280, 720);
  set_window_icon_from_asset(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  setup_taskbar_progress_channel(self, view);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_object(&self->taskbar_progress_channel);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
