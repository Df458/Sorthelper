namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/DefaultView.ui")]
	public class DefaultView : View, Gtk.Box
    {
        [GtkChild]
        public Gtk.Label file_label;

        public bool load(File infile)
        {
            file_label.label = infile.get_basename();
            return true;
        }

        public void display() {}

        public void resize() {}

        public void unload() {}
	}
}
