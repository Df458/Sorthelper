using GLib;
using Gee;
namespace SortHelper{
	public class EmptyView : View, Granite.Widgets.Welcome{
        public EmptyView() {
            base("Conglaturation", "You are win");
        }

        public bool load() {
            return true;
        }

        public void display() {}

        public void unload() {}

        public void fileRemoved() {}
	}
}

