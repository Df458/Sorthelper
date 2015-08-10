using GLib;
using Gee;
namespace SortHelper
{
	public class DefaultView : View, Granite.Widgets.Welcome
    {
        public DefaultView()
        {
            base("No viewer exists for:", "file");
        }

        public bool load(File infile)
        {
            subtitle = infile.get_basename();
            return true;
        }

        public void display() {}

        public void unload() {}

        public void fileRemoved() {}
	}
}
