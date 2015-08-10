using GLib;
using Gee;
namespace SortHelper{
	public interface View : Gtk.Widget{
        public abstract bool load(File to_display);
        public abstract void fileRemoved();
        public abstract void display();
        public abstract void unload();
	}
}
