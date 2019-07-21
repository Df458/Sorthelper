using GLib;
using Gee;
namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/ArchiveView.ui")]
	public class ArchiveView : View, Gtk.ScrolledWindow
    {
        Archive.Read archive;
        FileStream fs;
        [GtkChild]
        Gtk.Label label;

        public ArchiveView()
        {
            archive = new Archive.Read();
            archive.support_filter_all();
            archive.support_format_all();
        }

        public bool load(File infile)
        {
            fs = FileStream.open(infile.get_path(), "r");
            Archive.Result res = archive.open_FILE(fs);
            if(res != Archive.Result.OK)
                return false;
            return true;
        }

        public void display()
        {
            unowned Archive.Entry e;
            label.label = "";
            while(archive.next_header(out e) == Archive.Result.OK)
                label.label += e.pathname() + "\n";
        }

        public void resize() {}

        public void unload()
        {
            archive.close();
        }
	}
}
