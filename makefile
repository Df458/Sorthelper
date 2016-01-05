CC=g++-4.8
VALA=valac
VALAFLAGS= -d . -g --thread -o sorthelper -b ../src --pkg granite --pkg glib-2.0 --pkg gstreamer-1.0 --pkg gstreamer-video-1.0 --pkg gdk-x11-3.0 --pkg webkit2gtk-4.0 --pkg libarchive --pkg posix --pkg dflib -X -ldflib

vfiles := $(wildcard src/*.vala) $(wildcard src/*/*.vala)

all: $(cobjects)
	$(VALA) $(vfiles) $(VALAFLAGS)

clean:
	rm -f sorthelper

install:
	cp sorthelper /usr/local/bin
	cp -f data/org.df458.sorthelper.gschema.xml /usr/share/glib-2.0/schemas
	glib-compile-schemas /usr/share/glib-2.0/schemas
