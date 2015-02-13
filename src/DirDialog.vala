using Gtk;
using Granite.Widgets;
namespace SortHelper {
class DirDialog : Dialog {
    private Entry name_input;

    public DirDialog(Window owner) {
        this.set_transient_for(owner);
        this.set_modal(true);
        this.title = "Add a category";

        add_buttons("Cancel", 0, "Add", 1);
        this.response.connect((sig) => {
            if(sig == 0) {
                name_input.set_text("");
                this.hide();
            } else if(sig == 1) {
                App.main_window.build_directory(name_input.get_text());
                name_input.set_text("");
                this.hide();
            }
        });


        Box content_box = get_content_area() as Box;

        name_input = new Entry();
        name_input.editable = true;
        content_box.pack_start(name_input, false, true, 0);
    }
}
}
