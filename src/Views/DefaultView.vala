using GLib;
using Gee;
namespace SortHelper{
	public class DefaultView : View, Granite.Widgets.Welcome{
        public DefaultView() {
            base("No viewer exists for:", "file");
        }

        public bool load() {
            subtitle = App.to_display[0].get_basename();
            return true;
        }

        public void display() {}

        public void unload() {}

        public void fileRemoved() {}
	}
}
