CC=g++-4.8
VALA=valac
VALAFLAGS= -d . -o SortHelper -b ../src --pkg granite --pkg glib-2.0 --pkg unity

vfiles := $(wildcard ../src/*.vala) $(wildcard ../src/*/*.vala)

all: $(cobjects)
	$(VALA) $(vfiles) $(VALAFLAGS)

clean:
	rm -rf obj/*.o

install:
	cp SortHelper /usr/local/bin
