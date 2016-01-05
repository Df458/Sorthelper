using Gtk;

namespace SortHelper {

public class SettingsPane : SettingsGrid
{
    private CheckButton load_last_check;
    private CheckButton save_folder_check;
    private ButtonBox   response_buttons;

    private Button save_button;
    private Button cancel_button;
    private Button reset_button;

    public SettingsPane()
    {
        this.margin = 18;
        this.halign = Align.CENTER;
        load_last_check   = new CheckButton.with_label("Load the last folder on startup");
        save_folder_check = new CheckButton.with_label("Save my folder hierarchy");
        response_buttons  = new ButtonBox(Orientation.HORIZONTAL);
        save_button   = new Button.with_label("Save");
        cancel_button = new Button.with_label("Cancel");
        reset_button  = new Button.with_label("Reset");

        response_buttons.spacing = 6;
        reset_button.get_style_context().add_class(STYLE_CLASS_DESTRUCTIVE_ACTION);
        save_folder_check.sensitive = false;

        this.add(null, load_last_check, 0);
        this.add(null, save_folder_check, 0);
        response_buttons.add(save_button);
        response_buttons.add(cancel_button);
        response_buttons.add(reset_button);
        response_buttons.set_child_secondary(reset_button, true);
        this.attach(response_buttons, 0, 1, 2, 1);

        connect_signals();
    }

    public void sync()
    {
        load_last_check.active   = App.app_settings.get_boolean("open-last");
        //save_folder_check.active = App.app_settings.get_boolean("");
    }

    public signal void done();

    private void save()
    {
        App.app_settings.set_boolean("open-last", load_last_check.active);
        //App.app_settings.set_boolean(, save_folder_check.active);
        done();
    }

    private void reset()
    {
        load_last_check.active = true;
        save_folder_check.active = true;
    }

    private void connect_signals()
    {
        save_button.clicked.connect(save);
        cancel_button.clicked.connect(() => { done(); });
        reset_button.clicked.connect(reset);
    }
}
}
