CC=g++-4.8
VALA=valac
VALAFLAGS= -d . -g --thread -o sorthelper -b ../src --pkg granite --pkg glib-2.0 --pkg gstreamer-0.10 --pkg gstreamer-interfaces-0.10 --pkg gdk-x11-3.0

vfiles := $(wildcard src/*.vala) $(wildcard src/*/*.vala)

all: $(cobjects)
	$(VALA) $(vfiles) $(VALAFLAGS)

install:
	cp sorthelper /usr/local/bin
