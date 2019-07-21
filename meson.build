project('sorthelper', ['vala', 'c'],
        version : '0.2',
        license : 'GPLv3')

vala = meson.get_compiler('vala')
gcc = meson.get_compiler('c')

gnome = import('gnome')
glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gdkx = dependency('gdk-x11-3.0')
gee = dependency('gee-0.8')
dflib = subproject('dflib').get_variable('dflib')
gstreamer = dependency('gstreamer-1.0')
gstreamer_v = dependency('gstreamer-video-1.0')
webkitgtk = dependency('webkit2gtk-4.0')
posix = vala.find_library('posix')
libarchive = dependency('libarchive')
sqlheavy = dependency('sqlheavy-0.1')

resource_path = 'data/sorthelper.gresource.xml'
resources = gnome.compile_resources('resources', resource_path, source_dir : 'data')
install_data(['data/org.df458.sorthelper.gschema.xml'], install_dir: '/usr/share/glib-2.0/schemas')

deps = [glib, gobject, gee, dflib, gdkx, gstreamer, gstreamer_v, webkitgtk, posix, libarchive, sqlheavy]

subdir('src')

run_command('ctags', '-R', 'src')
