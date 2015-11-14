using GLib;
using Gee;
namespace SortHelper
{
public class MainWindow : Gtk.ApplicationWindow
{
    public Gtk.Box container1;
    private Gtk.HeaderBar toolbar;
    private Gtk.Paned panedview;

    private Gtk.Box settingsview;
    private Gtk.CheckButton autoreloadbutton;
    private Gtk.ButtonBox settings_confirm_buttons;

    private Gtk.Button skipbutton;
    private Gtk.Button deletebutton;
    private Gtk.ToggleButton batchbutton;
    private Gtk.Button addbutton;
    private Gtk.Button newbutton;
    private Gtk.Button openbutton;
    private Gtk.Button undobutton;
    private Gtk.Button redobutton;
    private Gtk.Button errorbutton;
    private Gtk.Button nextbutton;
    private Gtk.Button backbutton;
    private Gtk.MenuButton menubutton;
    private AddFolderPopover add_pop;
    private OpenFolderPopover open_pop;
    private OpenFolderPopover target_pop;
    private GLib.Rand random;
    public string current_image_location;
    public File current_file;
    public Gtk.InfoBar errorbar;
    private Gtk.ActionBar status_bar;
    private Gtk.Label file_label;
    public int selected = 0;
    private bool overlay_hover = false;

    public ImageFullView fullview;
    public VideoView vidview;
    public EmptyView empty_view;
    public DefaultView default_view;
    public AudioView audio_view;
    public WebView web_view;
    public ArchiveView archive_view;
    public ComicView comic_view;
    public WelcomeView welcome_view;

    public Gtk.SearchEntry search;
    public Gtk.Box list_box;
    public Gtk.AccelGroup accel;
    private View current_view;
    private View chosen_view;
    private Gtk.Overlay view_overlay;

    public bool filtering = false;
    public bool filterreset = false;
    private Motion failure_list;
    private bool failed_last = false;

    private uint last_motion_timer;
    private bool has_last_motion = false;

    private Gtk.ButtonBox control_box;
    private Gtk.Revealer control_revealer;

    private Gtk.TreeView places_view;
    private Gtk.TreeStore places_data;
    private Gtk.TreeModelFilter places_filter;
    private string filter_key;
    private Gtk.Menu places_menu;
 
    public MainWindow()
    {
        random = new GLib.Rand();
        accel = new Gtk.AccelGroup();
        this.add_accel_group(accel);
        set_events(Gdk.EventMask.ALL_EVENTS_MASK);

        // Init Windows and Popovers
        fullview = new ImageFullView();
        default_view = new DefaultView();
        empty_view = new EmptyView();
        audio_view = new AudioView();
        vidview = new VideoView();
        web_view = new WebView();
        archive_view = new ArchiveView();
        comic_view = new ComicView();
        welcome_view = new WelcomeView();

        current_view = welcome_view;
        chosen_view = empty_view;

        // Init Structural Widgets
        toolbar = new Gtk.HeaderBar();
        status_bar = new Gtk.ActionBar();
        panedview = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
        settingsview = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        list_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        // TODO: Consider making errorbar a class as well
        errorbar = new Gtk.InfoBar.with_buttons("Replace", 1, "Delete", 2);
        Gtk.Container content = errorbar.get_content_area();
        container1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        view_overlay = new Gtk.Overlay();
        control_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
        control_revealer = new Gtk.Revealer();
        control_revealer.set_reveal_child(false);
        Gtk.ScrolledWindow places_wrapper = new Gtk.ScrolledWindow(null, null);

        places_data = new Gtk.TreeStore(4, typeof(string), typeof(string), typeof(bool), typeof(bool));
        places_data.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        places_filter = new Gtk.TreeModelFilter(places_data, null);
        places_filter.set_visible_column(2);
        places_view = new Gtk.TreeView.with_model(places_filter);
        places_view.enable_search = true;
        places_view.search_column = 0;
        places_view.set_headers_visible(false);
        places_view.set_search_equal_func((model, column, key, iter) =>{
            string name = "";
            model.get(iter, 0, out name);
            return !name.down().contains(key.down());
        });
        Gtk.CellRendererText name_renderer = new Gtk.CellRendererText();
        name_renderer.editing_canceled.connect(() => {
            name_renderer.editable = false;
        });
        name_renderer.edited.connect((path, text) => {
            Gtk.TreeIter iter;
            string data_path = "";
            string old_name = "";
            Gtk.TreePath child_path = places_filter.convert_path_to_child_path(new Gtk.TreePath.from_string(path));
            places_data.get_iter(out iter, child_path);
            if(!places_data.iter_is_valid(iter)) {
                stderr.printf("Error: Couldn't find iterator at %s->%s\n", path, child_path.to_string());
                return;
            }
            places_data.get(iter, 0, out old_name, 1, out data_path);
            if(old_name == text)
                return;
            File f = File.new_for_uri(data_path);
            try {
                f = f.set_display_name(text);
                places_data.set(iter, 0, text, 1, f.get_uri());
            } catch(Error e) {
                stderr.printf("Error renaming directory: %s\n", e.message);
            }
            name_renderer.editable = false;
        });
        Gtk.TreeViewColumn col_name = new Gtk.TreeViewColumn.with_attributes("Name", name_renderer, "text", 0, null);
        places_view.insert_column(col_name, -1);
        SimpleActionGroup branch_group = new SimpleActionGroup();
        SimpleAction act_hide = new SimpleAction("hide", null);
        act_hide.set_enabled(true);
        act_hide.activate.connect(() => {
            Gtk.TreePath path = null;
            Gtk.TreeViewColumn column;
            Gtk.TreeIter iter;
            places_view.get_cursor(out path, out column);
            if(path != null) {
                path = places_filter.convert_path_to_child_path(path);
                places_data.get_iter(out iter, path);
                places_data.remove(ref iter);
            }
        });
        branch_group.add_action(act_hide);
        SimpleAction act_rename = new SimpleAction("rename", null);
        act_rename.set_enabled(true);
        act_rename.activate.connect(() => {
            Gtk.TreePath path = null;
            Gtk.TreeViewColumn column;
            places_view.get_cursor(out path, out column);
            if(path != null) {
                name_renderer.editable = true;
                places_view.set_cursor(path, col_name, true);
                name_renderer.editable = false;
            }
        });
        branch_group.add_action(act_rename);
        places_view.insert_action_group("branch", branch_group);
        places_view.row_activated.connect((path, column) => {
            Gtk.TreeIter iter;
            Gtk.TreePath child_path = places_filter.convert_path_to_child_path(path);
            places_data.get_iter(out iter, child_path);
            if(!places_data.iter_is_valid(iter)) {
                stderr.printf("Error: Couldn't find iterator at %s->%s\n", path.to_string(), child_path.to_string());
                return;
            }
            string move_path = "";
            places_data.get(iter, 1, out move_path);

            if(App.batch_mode) {
                stderr.printf("Moving several files...\n");
                Motion err = App.move_files(move_path, App.to_display);
                if(err.new_position.size != 0)
                    move_failed(err);
                else
                    stderr.printf("Move succeeded.\n");
            } else {
                stderr.printf("Moving single file...");
                stderr.printf("(%d/%d)\n", selected, App.to_display.size);
                bool success = App.move_file(move_path, App.to_display[selected]);
                if(!success)
                    move_failed_single(move_path);
                else
                    stderr.printf("Move succeeded.\n");
                if(selected >= App.to_display.size)
                    selected--;
            }
            if(App.to_display.size == 0)
                loadFile();
            else
                resetView();
        });
        Menu places_menu_model = new Menu();
        places_menu_model.append("Hide Branch", "branch.hide");
        places_menu_model.append("Rename Branch", "branch.rename");
        places_menu = new Gtk.Menu.from_model(places_menu_model);
        places_menu.attach_to_widget(places_view, null);
        places_view.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        places_view.button_press_event.connect((event) => {
            if(event.button == 3) {
                places_view.popup_menu();
            }
            return false;
        });
        places_view.popup_menu.connect(() => {
            places_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            return false;
        });

        toolbar.set_title("Sorthelper");
        toolbar.set_subtitle("Completion: ");
        toolbar.set_show_close_button(true);
        toolbar.set_decoration_layout("menu:close");
        errorbar.set_show_close_button(true);
        errorbar.set_response_sensitive(1, true);
        errorbar.set_response_sensitive(2, true);
        errorbar.set_message_type(Gtk.MessageType.ERROR);
        content.add(new Gtk.Label("A file with the same name already exists!"));
        errorbar.response.connect(respond);
        // TODO: This function does nothing, but we should add resizing functions to each view class
        panedview.size_allocate.connect(resizeView);
        panedview.set_position(200);
        view_overlay.set_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        control_box.valign = Gtk.Align.CENTER;

        // Init Display Widgets
        skipbutton = new Gtk.Button.from_icon_name("go-next-symbolic");
        deletebutton = new Gtk.Button.from_icon_name("edit-delete-symbolic");
        deletebutton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        newbutton = new Gtk.Button.from_icon_name("document-new-symbolic");
        target_pop = new OpenFolderPopover(newbutton);
        addbutton = new Gtk.Button.from_icon_name("folder-new-symbolic");
        add_pop = new AddFolderPopover(addbutton);
        openbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
        open_pop = new OpenFolderPopover(openbutton);
        undobutton = new Gtk.Button.from_icon_name("edit-undo-symbolic");
        redobutton = new Gtk.Button.from_icon_name("edit-redo-symbolic");
        errorbutton = new Gtk.Button.from_icon_name("emblem-important-symbolic");

        nextbutton = new Gtk.Button.from_icon_name("go-next-symbolic");
        nextbutton.get_style_context().add_class(Gtk.STYLE_CLASS_OSD);
        backbutton = new Gtk.Button.from_icon_name("go-previous-symbolic");
        backbutton.get_style_context().add_class(Gtk.STYLE_CLASS_OSD);
        batchbutton = new Gtk.ToggleButton();
        autoreloadbutton = new Gtk.CheckButton.with_label("Load the last sorted folder on startup");
        autoreloadbutton.set_active(App.auto_reload);

        file_label = new Gtk.Label("Stuff goes here");
        search = new Gtk.SearchEntry();

        skipbutton.add_accelerator("clicked", accel, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        skipbutton.clicked.connect(loadFile);
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.clicked.connect(removeFile);
        newbutton.clicked.connect(() => {target_pop.show_all();});
        addbutton.clicked.connect(() => {add_pop.show_all();});
        openbutton.clicked.connect(() => {open_pop.show_all();});
        add_pop.file_created.connect(build_directory);
        open_pop.file_chosen.connect((file) => {
            addDir(file, null);
        });
        target_pop.file_chosen.connect((file) => {
            App.item_list.load_folder(file);
            undobutton.set_sensitive(false);
            redobutton.set_sensitive(false);
            loadFile();
        });
        undobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        undobutton.set_sensitive(false);
        undobutton.clicked.connect(()=>{
            App.undo_list.undo();
            if(App.undo_list.previous_count == 0)
                undobutton.set_sensitive(false);
            redobutton.set_sensitive(true);
        });
        redobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        redobutton.set_sensitive(false);
        redobutton.clicked.connect(()=>{
            App.undo_list.redo();
            if(App.undo_list.next_count == 0)
                redobutton.set_sensitive(false);
            undobutton.set_sensitive(true);
        });
        errorbutton.set_sensitive(false);
        control_revealer.add(control_box);
        control_revealer.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE);
        nextbutton.clicked.connect(() => { go_next(); });
        nextbutton.halign = Gtk.Align.END;
        nextbutton.valign = Gtk.Align.CENTER;
        nextbutton.margin = 10;
        nextbutton.enter_notify_event.connect((e) =>{
            overlay_hover = true;
            return false;
        });
        nextbutton.leave_notify_event.connect((e) =>{
            overlay_hover = false;
            return false;
        });
        backbutton.clicked.connect(() => { go_prev(); });
        backbutton.halign = Gtk.Align.START;
        backbutton.valign = Gtk.Align.CENTER;
        backbutton.margin = 10;
        backbutton.enter_notify_event.connect((e) =>{
            overlay_hover = true;
            return false;
        });
        backbutton.leave_notify_event.connect((e) =>{
            overlay_hover = false;
            return false;
        });
        //batchbutton.set_label("Batch Mode");
        batchbutton.set_image(new Gtk.Image.from_icon_name("edit-select-all", Gtk.IconSize.SMALL_TOOLBAR));
        batchbutton.set_active (true);
        batchbutton.toggled.connect(swapBatch);

        GLib.Menu main_menu = new GLib.Menu();
        GLib.MenuItem settings_item = new GLib.MenuItem("Settings", "win.settings");
        main_menu.append_item(settings_item);
        GLib.SimpleAction settings_action = new GLib.SimpleAction("settings", null);
        settings_action.set_enabled(true);
        settings_action.activate.connect(() => {
            container1.remove(panedview);
            container1.pack_end(settingsview, true, true);
            settings_action.set_enabled(false);
            autoreloadbutton.set_active(App.auto_reload);
            container1.show_all();
        });
        this.add_action(settings_action);
        menubutton = new Gtk.MenuButton();
        menubutton.direction = Gtk.ArrowType.UP;
        menubutton.set_image(new Gtk.Image.from_icon_name("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
        menubutton.set_menu_model(main_menu);

        settings_confirm_buttons = new Gtk.HButtonBox();
        Gtk.Button settings_cancel_button = new Gtk.Button.with_label("Cancel");
        settings_cancel_button.clicked.connect(() => {
            container1.remove(settingsview);
            container1.pack_end(panedview, true, true);
            settings_action.set_enabled(true);
            container1.show_all();
        });
        Gtk.Button settings_confirm_button = new Gtk.Button.with_label("Confirm");
        settings_confirm_button.clicked.connect(() => {
            App.app_settings.set_boolean("open-last", autoreloadbutton.get_active());
            container1.remove(settingsview);
            container1.pack_end(panedview, true, true);
            settings_action.set_enabled(true);
            container1.show_all();
        });
        settings_confirm_buttons.add(settings_cancel_button);
        settings_confirm_buttons.add(settings_confirm_button);

        search.set_placeholder_text("Filter...");
        search.search_changed.connect(() => {
            traversal_filter.begin(search.text);
        });
        places_view.set_search_entry(search);
        search.activate.connect(() => {
            Gtk.TreePath path = null;
            Gtk.TreeViewColumn column;
            places_view.get_cursor(out path, out column);
            if(path != null)
                places_view.row_activated(path, column);
        });

        // Build Structure
        this.set_titlebar(toolbar);
        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.destroy.connect(on_exit);

        toolbar.pack_start(newbutton);
        toolbar.pack_start(skipbutton);
        toolbar.pack_start(batchbutton);
        toolbar.pack_end(deletebutton);
        toolbar.pack_end(redobutton);
        toolbar.pack_end(undobutton);
        toolbar.pack_end(errorbutton);

        view_overlay.add(current_view);
        view_overlay.add_overlay(control_revealer);
        control_box.add(backbutton);
        control_box.add(nextbutton);

        list_box.pack_start(search, false, false);
        places_wrapper.add(places_view);
        list_box.pack_start(places_wrapper, true, true);
        status_bar.set_center_widget(file_label);
        status_bar.pack_start(addbutton);
        status_bar.pack_start(openbutton);
        status_bar.pack_end(menubutton);

        panedview.pack1(list_box, false, true);
        panedview.pack2(view_overlay, true, true);
        settingsview.pack_start(autoreloadbutton, true, true);
        settingsview.pack_end(settings_confirm_buttons, false, false);
        container1.pack_end(status_bar, false, false);
        container1.pack_end(panedview, true, true);

        this.add(container1);
        this.show_all();
    }
    
    void respond (int response_id)
    {
        if(response_id == 1)
            replaceFile();
        if(response_id == 2)
            removeFile();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
    }
    
    public void loadDirItems()
    {
        //default_item.clear();
        //libitem = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.lib"));
        //default_item.add(libitem);
        //libitem.expand_with_parents();
        addDir(File.new_for_path("/home/df458/Documents/.Collections/.lib"), null);
    }
    
    public void resizeView()
    {
    }

    public void go_next()
    {
        ++selected;
        file_label.set_text(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view.load(App.to_display[selected]);
        current_view.display();
        backbutton.sensitive = true;
        if(selected >= App.to_display.size - 1) {
            nextbutton.sensitive = false;
        }
        this.show_all();
    }

    public void go_prev()
    {
        --selected;
        file_label.set_text(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view.load(App.to_display[selected]);
        current_view.display();
        nextbutton.sensitive = true;
        nextbutton.sensitive = true;
        if(selected <= 0) {
            backbutton.sensitive = false;
        }
        this.show_all();
    }
    
    public void loadFile()
    {
        selected = 0;
        nextbutton.sensitive = false;
        backbutton.sensitive = false;
        search.grab_focus();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
        if(App.item_list.is_empty()) {
            toolbar.set_subtitle("Completion: " + (App.item_list.orig_size - App.item_list.size).to_string() + "/" + App.item_list.orig_size.to_string());
            if(App.undo_list.previous_count > 0)
                undobutton.set_sensitive(true);
            redobutton.set_sensitive(App.undo_list.next_count > 0);
            set_content(empty_view);
            return;
        }

        getFiles.begin((obj, res) => {
            display_files();
        });
    }
    
    public void swapBatch()
    {
        App.batch_mode = batchbutton.get_active();
    }
    
    public void replaceFile()
    {
        search.grab_focus();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
        if(App.batch_mode) {
            stdout.printf("Replacing %d images...\n", App.to_display.size);
            while(App.to_display.size > 0) {
                try {
                    File f = File.new_for_path (App.to_display[0].get_path());
                    string name = f.query_info ("standard::*", 0).get_name();
                    File dest = File.new_for_path(App.last_dest + "/" + name);
                    stdout.printf("Moving image %s...\n", App.to_display[0].get_basename());
                    App.to_display[0].move(dest, FileCopyFlags.OVERWRITE);
                } catch(Error e) {
                    stderr.printf("Error: %s", e.message);
                }
                App.item_list.remove(App.to_display[0]);
                App.to_display.remove_at(0);
            }
        } else {
            try {
                File f = File.new_for_path (App.to_display[fullview.image_id].get_path());
                string name = f.query_info ("standard::*", 0).get_name();
                File dest = File.new_for_path(App.last_dest + "/" + name);
                stdout.printf("Moving image %s...\n", App.to_display[fullview.image_id].get_basename());
                App.to_display[fullview.image_id].move(dest, FileCopyFlags.OVERWRITE);
            } catch(Error e) {
                stderr.printf("Error: %s", e.message);
            }
            App.item_list.remove(App.to_display[fullview.image_id]);
            App.to_display.remove_at(fullview.image_id);
        }
        if(App.to_display.size == 0) {
            loadFile();
        } else {
            resetView();
        }
    }

    public void removeFile()
    {
        search.grab_focus();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
        if(App.batch_mode) {
            stdout.printf("Removing %d images...\n", App.to_display.size);
            while(App.to_display.size > 0) {
                try {
                    stdout.printf("Deleting image %s...\n", App.to_display[0].get_basename());
                    App.to_display[0].delete();
                } catch(Error e) {
                    stderr.printf("Error: %s", e.message);
                }
                App.item_list.remove(App.to_display[0]);
                App.to_display.remove_at(0);
            }
        } else {
            try {
                stdout.printf("Deleting image %s...\n", App.to_display[fullview.image_id].get_basename());
                App.to_display[fullview.image_id].delete();
            } catch(Error e) {
            stderr.printf("Error: %s", e.message);
            }
            App.item_list.remove(App.to_display[fullview.image_id]);
            App.to_display.remove_at(fullview.image_id);
        }
        if(App.to_display.size == 0) {
            loadFile();
        } else {
            resetView();
        }
    }
    
    public async bool getFiles()
    {
        File infile = App.item_list.getFilesByCount()[0];
        App.to_display = yield App.item_list.getFilesByExpansion(infile);
        return true;
    }
    
    public void display_files()
    {
        toolbar.set_subtitle("Completion: " + (App.item_list.orig_size - App.item_list.size).to_string() + "/" + App.item_list.orig_size.to_string());
        if(App.undo_list.previous_count > 0)
            undobutton.set_sensitive(true);
        redobutton.set_sensitive(App.undo_list.next_count > 0);
        control_revealer.set_reveal_child(false);
        if(App.to_display.size > 1) {
            nextbutton.sensitive = true;
            control_revealer.set_reveal_child(true);
        }
        chosen_view.unload();
        if(App.to_display.is_empty) {
            set_content(empty_view);
             file_label.set_text("");
        } else {
            file_label.set_text(App.to_display[0].get_basename() + (App.to_display.size > 1 ? " (" + "1" + "/" + App.to_display.size.to_string() + ")" : ""));
            chosen_view = default_view;
            try {
                string filetype = App.to_display[0].query_info("standard::content-type", 0, null).get_content_type();
                stdout.printf("\nGot type: %s\n\n", filetype);
                switch(filetype) {
                    case "audio/mpeg":
                        chosen_view = audio_view;
                        break;

                    case "image/gif":
                    case "image/jpeg":
                    case "image/png":
                        chosen_view = fullview;
                        break;

                    case "video/mp4":
                    case "video/webm":
                    case "video/x-ms-wmv":
                    case "video/x-flv":
                        chosen_view = vidview;
                        break;

                    case "application/vnd.adobe.flash.movie":
                        web_view.is_swf = true;
                        chosen_view = web_view;
                        break;

                    case "application/x-cbr":
                    case "application/x-cbt":
                    case "application/x-cbz":
                        chosen_view = comic_view;
                        break;

                    case "application/x-rar-compressed":
                    case "application/zip":
                        chosen_view = archive_view;
                        break;

                    default:
                        chosen_view = default_view;
                        break;
                }
            } catch(Error e) {
                stderr.printf("Error getting mimetype: %s\n", e.message);
            }
            chosen_view.load(App.to_display[0]);
            set_content(chosen_view);
            chosen_view.display();
        }
    }

    public void resetView()
    {
        if(selected >= App.to_display.size)
            selected = App.to_display.size - 1;
        file_label.set_text(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view.load(App.to_display[selected]);
        current_view.display();
        control_revealer.set_reveal_child(App.to_display.size > 1);
        if(selected >= App.to_display.size - 1) {
            nextbutton.sensitive = false;
        }
        if(selected <= 0) {
            backbutton.sensitive = false;
        }
        this.show_all();
    }

    public void set_content(View widget)
    {
        int pos = panedview.get_position();
        view_overlay.remove(current_view);
        panedview.set_position(0);
        view_overlay.add(widget);
        current_view = widget;
        panedview.set_position(pos);
        this.show_all();
    }

    public void build_directory(string name)
    {
        Gtk.TreeIter iter;
        Gtk.TreePath path;
        places_view.get_cursor(out path, null);
        Gtk.TreePath child_path = places_filter.convert_path_to_child_path(path);
        places_data.get_iter(out iter, child_path);
        string move_path = "";
        places_data.get(iter, 1, out move_path);
        File f = File.new_for_uri(move_path + "/" + name);
        try {
            f.make_directory();
        } catch(Error e) {
            warning("Couldn't Create Tag: %s", e.message);
        }
        addDir(f, iter);
    }

    public void move_failed(Motion err)
    {
        container1.pack_end(errorbar, false, false);
        failed_last = true;
        failure_list = err;
        errorbutton.set_sensitive(true);
        // TODO: Display errors
        show_all();
    }

    public void move_failed_single(string dest)
    {
        container1.pack_end(errorbar, false, false);
        failed_last = true;
        failure_list = Motion();
        failure_list.new_position = new ArrayList<File>();
        failure_list.old_folder = new ArrayList<string>();
        errorbutton.set_sensitive(true);
        foreach(File f in App.to_display) {
            if(f == current_file)
                failure_list.old_folder.add(dest);
            else
                failure_list.old_folder.add("");
            failure_list.new_position.add(f);
        }
        // TODO: Display errors
        show_all();
    }
    
    private void on_exit()
    {
        chosen_view.unload();
        App.save_last();
    }

    public bool itemFilter(Granite.Widgets.SourceList.Item item)
    {
        return item is BaseItem || ((DirItem)item).has(search.text);
    }

    public void addDir(File f, Gtk.TreeIter? parent_iter)
    {
        Gtk.TreeIter iter;
        places_data.append(out iter, parent_iter);

        places_data.set(iter, 0, f.get_basename(), 1, f.get_uri(), 2, true);
        FileInfo info;
        try{
            info = f.query_info ("standard::*", 0);
            FileEnumerator enumerator = f.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                if(file_info.get_file_type () == FileType.DIRECTORY){
                    addDir(f.resolve_relative_path (file_info.get_name ()), iter);
                }
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return;
        }
    }

    public async void traversal_filter(string key)
    {
        Gtk.TreeIter iter;
        places_data.get_iter_first(out iter);
        if(key.length == 0)
            places_view.collapse_all();
        yield traversal_step(iter, key.down());
        places_filter.refilter();
        if(key.length != 0)
            places_view.expand_all();
    }

    public async bool traversal_step(Gtk.TreeIter iter, string key, bool carry = false)
    {
        bool back = false;
        bool temp = false;
        do {
            Gtk.TreeIter child;
            ushort val = 0;
            bool expanded = false;
            string name = "";
            places_data.get(iter, 0, out name, 3, out expanded);
            if(key.length == 0 || name.down().contains(key)) {
                val = 2;
                //if(key.length == 0 && expanded)
                    //places_view.expand_row(places_data.get_path(iter), false);
            }
            else if(carry)
                val = 1;
            bool keep = val != 0;
            if(places_data.iter_children(out child, iter)) {
                temp = yield traversal_step(child, key, val == 2);
                keep = temp || keep;
            }
            places_data.set(iter, 2, keep);
            back = back || keep;
        } while(places_data.iter_next(ref iter));
        return back;
    }
}
}
