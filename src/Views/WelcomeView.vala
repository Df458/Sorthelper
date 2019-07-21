using GLib;
using Gee;
namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/WelcomeView.ui")]
	public class WelcomeView : View, Gtk.Box
    {
        public WelcomeView() {}

        public bool load(File infile)
        {
            return true;
        }

        public void display() {}

        public void resize() {}

        public void unload() {}
	}
}

