using GLib;
using Gee;
namespace SortHelper
{
public class OpenFolderPopover : Gtk.Popover
{
    private Gtk.Box layout_box;
    private Gtk.FileChooserButton folder_selector;
    private Gtk.Button confirm_button;

    public signal void file_chosen(File selection);

    public OpenFolderPopover(Gtk.Widget target)
    {
        layout_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        folder_selector = new Gtk.FileChooserButton("Add a Folder", Gtk.FileChooserAction.SELECT_FOLDER);
        confirm_button = new Gtk.Button.with_label("Open");

        confirm_button.clicked.connect(() => {
            file_chosen(folder_selector.get_file());
            this.hide();
        });

        layout_box.pack_start(folder_selector);
        layout_box.pack_start(confirm_button);

        this.child = layout_box;
        this.relative_to = target;
    }
}
}
