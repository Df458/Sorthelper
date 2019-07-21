namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/EmptyView.ui")]
	public class EmptyView : View, Gtk.Box
    {
        public bool load(File infile) { return true; }

        public void display() {}

        public void resize() {}

        public void unload() {}
	}
}
