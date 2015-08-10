using GLib;
using Gee;
namespace SortHelper
{
public class AddFolderPopover : Gtk.Popover
{
    private Gtk.Box layout_box;
    private Gtk.Entry name_input;
    private Gtk.Button confirm_button;

    public signal void file_created(string name);

    public AddFolderPopover(Gtk.Widget target)
    {
        layout_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        name_input = new Gtk.Entry();
        confirm_button = new Gtk.Button.with_label("Add...");

        name_input.editable = true;
        name_input.activate.connect(() => {
            file_created(name_input.get_text());
            name_input.set_text("");
            this.hide();
        });
        confirm_button.clicked.connect(() => {
            file_created(name_input.get_text());
            name_input.set_text("");
            this.hide();
        });

        layout_box.pack_start(name_input);
        layout_box.pack_start(confirm_button);

        this.child = layout_box;
        this.relative_to = target;
    }
}
}
