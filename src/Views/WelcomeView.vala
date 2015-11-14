using GLib;
using Gee;
namespace SortHelper
{
	public class WelcomeView : View, Granite.Widgets.Welcome
    {
        public WelcomeView()
        {
            base("Welcome", "Select a folder above to begin sorting");
        }

        public bool load(File infile)
        {
            return true;
        }

        public void display() {}

        public void unload() {}
	}
}

