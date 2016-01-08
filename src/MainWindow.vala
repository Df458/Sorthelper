using Gee;
using Gtk;
namespace SortHelper
{
public class MainWindow : ApplicationWindow
{
    private     Rand random;
    private     AccelGroup accel;
    public int  selected = 0;
    public File current_file;

    private HeaderBar toolbar;

    private Paned main_paned;
    private Box   main_box;
    private Box   list_box;
    private Box   view_box;
    private Box   control_box;
    private Box   control_link_box;
    private Stack main_stack;
    private Stack secondary_stack;
    private Stack mode_stack;

    private MenuButton   menubutton;
    private Button       undobutton;
    private Button       redobutton;
    private Button       skipbutton;
    private Button       nextbutton;
    private Button       backbutton;
    private Button       deletebutton;
    private Button       openbutton;
    private ToggleButton batchbutton;

    private Motion failure_list;
    private bool failed_last = false;

    private ImageFullView fullview;
    private VideoView     vidview;
    private EmptyView     empty_view;
    private DefaultView   default_view;
    private AudioView     audio_view;
    private WebView       web_view;
    private ArchiveView   archive_view;
    private ComicView     comic_view;
    private WelcomeView   welcome_view;
    private View          chosen_view;
    private Overlay       view_overlay;

    private SettingsPane  settings;

    private InfoBar errorbar;

    private SearchEntry     search;
    private TreeView        places_view;
    private TreeStore       places_data;
    private TreeModelFilter places_filter;
    private ScrolledWindow  places_wrapper;

    private OpenFolderPopover open_pop;
    private OpenFolderPopover target_pop;
    private AddFolderPopover  add_pop;

    private string filter_key;
    private bool   filtering = false;
    private bool   filterreset = false;

    private GLib.Menu main_menu;
    private Gtk.Menu places_menu;
 
    public MainWindow()
    {
        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_default_size (1024, 768);

        random = new GLib.Rand();
        accel = new Gtk.AccelGroup();
        this.add_accel_group(accel);
        set_events(Gdk.EventMask.ALL_EVENTS_MASK);

        init_structure();
        init_content();
        connect_signals();
        add_actions();
        init_menus();

        this.show_all();
    }

    private void init_structure()
    {
        toolbar          = new HeaderBar();
        main_paned       = new Paned(Orientation.HORIZONTAL);
        main_box         = new Box(Orientation.VERTICAL, 0);
        view_box         = new Box(Orientation.HORIZONTAL, 18);
        list_box         = new Box(Orientation.VERTICAL, 6);
        control_box      = new Box(Orientation.HORIZONTAL, 6);
        control_link_box = new Box(Orientation.HORIZONTAL, 0);
        mode_stack       = new Stack();
        main_stack       = new Stack();
        view_overlay     = new Overlay();
        secondary_stack  = new Stack();
        errorbar         = new Gtk.InfoBar.with_buttons("Replace", 1, "Delete", 2);
        settings         = new SettingsPane();

        toolbar.set_title("Sorthelper");
        toolbar.set_show_close_button(true);
        toolbar.set_decoration_layout("menu:close");
        control_box.halign = Align.END;
        control_box.valign = Align.END;
        control_box.margin = 18;
        control_link_box.get_style_context().add_class(STYLE_CLASS_LINKED);
        secondary_stack.visible = false;
        main_paned.set_position(200);

        // TODO: Consider making errorbar a class as well
        Gtk.Container content = errorbar.get_content_area();

        errorbar.set_show_close_button(true);
        errorbar.set_response_sensitive(1, true);
        errorbar.set_response_sensitive(2, true);
        errorbar.set_message_type(Gtk.MessageType.ERROR);
        content.add(new Gtk.Label("A file with the same name already exists!"));

        this.set_titlebar(toolbar);
        view_box.pack_start(main_stack, true, true);
        // TODO: Pack/Unpack this as needed
        //view_box.pack_start(secondary_stack, true, true);
        view_overlay.add(view_box);
        main_paned.pack1(list_box, false, true);
        main_paned.pack2(view_overlay, false, true);
        mode_stack.add_named(main_paned, "sort");
        mode_stack.add_named(settings, "settings");
        mode_stack.set_visible_child(main_paned);
        main_box.pack_start(mode_stack, true, true);
        this.add(main_box);
    }

    private void init_content()
    {
        menubutton   = new MenuButton();
        undobutton   = new Button.from_icon_name("edit-undo-symbolic");
        redobutton   = new Button.from_icon_name("edit-redo-symbolic");
        openbutton   = new Button.from_icon_name("folder-open-symbolic");
        nextbutton   = new Button.from_icon_name("go-next-symbolic");
        backbutton   = new Button.from_icon_name("go-previous-symbolic");
        skipbutton   = new Button.from_icon_name("view-refresh-symbolic");
        deletebutton = new Button.from_icon_name("list-remove-symbolic");
        batchbutton  = new ToggleButton();
        open_pop   = new OpenFolderPopover(openbutton);
        search     = new SearchEntry();
        target_pop = new OpenFolderPopover(menubutton);

        fullview     = new ImageFullView();
        default_view = new DefaultView();
        empty_view   = new EmptyView();
        audio_view   = new AudioView();
        vidview      = new VideoView();
        web_view     = new WebView();
        archive_view = new ArchiveView();
        comic_view   = new ComicView();
        welcome_view = new WelcomeView();

        chosen_view = empty_view;


        init_places_view();

        search.margin_top = 6;
        search.margin_left = 6;
        search.margin_right = 6;
        search.set_placeholder_text("Filter\u2026");
        search.set_tooltip_text("Filter\u2026");
        places_view.set_search_entry(search);

        openbutton.set_tooltip_text("Add Directories\u2026");
        menubutton.direction = ArrowType.DOWN;
        menubutton.set_image(new Image.from_icon_name("open-menu-symbolic", IconSize.SMALL_TOOLBAR));
        undobutton.set_tooltip_text("Main Menu");
        undobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        undobutton.set_sensitive(false);
        undobutton.set_tooltip_text("Undo");
        redobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        redobutton.set_sensitive(false);
        redobutton.set_tooltip_text("Redo");
        nextbutton.get_style_context().add_class(Gtk.STYLE_CLASS_OSD);
        backbutton.get_style_context().add_class(Gtk.STYLE_CLASS_OSD);
        nextbutton.halign = Gtk.Align.END;
        nextbutton.valign = Gtk.Align.CENTER;
        nextbutton.margin = 18;
        backbutton.halign = Gtk.Align.START;
        backbutton.valign = Gtk.Align.CENTER;
        backbutton.margin = 18;
        nextbutton.set_tooltip_text("Next File");
        backbutton.set_tooltip_text("Previous File");
        skipbutton.add_accelerator("clicked", accel, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        skipbutton.set_tooltip_text("Skip This Group");
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        skipbutton.set_tooltip_text("Delete");
        batchbutton.set_image(new Gtk.Image.from_icon_name("edit-select-all-symbolic", IconSize.BUTTON));
        batchbutton.add_accelerator("clicked", accel, 'b', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        batchbutton.set_active (true);
        batchbutton.set_tooltip_text("Batch Mode");

        toolbar.pack_start(openbutton);
        toolbar.pack_start(undobutton);
        toolbar.pack_start(redobutton);
        toolbar.pack_end(menubutton);
        control_link_box.add(skipbutton);
        control_link_box.add(deletebutton);
        control_box.add(batchbutton);
        control_box.add(control_link_box);
        view_overlay.add_overlay(nextbutton);
        view_overlay.add_overlay(backbutton);
        view_overlay.add_overlay(control_box);
        main_stack.add_named(default_view, "default");
        main_stack.add_named(fullview,     "image");
        main_stack.add_named(empty_view,   "empty");
        main_stack.add_named(audio_view,   "audio");
        main_stack.add_named(vidview,      "video");
        main_stack.add_named(web_view,     "web");
        main_stack.add_named(archive_view, "archive");
        main_stack.add_named(comic_view,   "comic");
        main_stack.add_named(welcome_view, "welcome");
        list_box.pack_start(search, false, false);
        places_wrapper.add(places_view);
        list_box.pack_start(places_wrapper, true, true);
    }

    private void init_places_view()
    {
        places_wrapper = new Gtk.ScrolledWindow(null, null);
        places_data    = new Gtk.TreeStore(4, typeof(string), typeof(string), typeof(bool), typeof(bool));
        places_filter  = new Gtk.TreeModelFilter(places_data, null);
        places_view    = new Gtk.TreeView.with_model(places_filter);
        add_pop        = new AddFolderPopover(places_view);
        // TODO: Move this
        CellRendererText name_renderer = new Gtk.CellRendererText();
        Gtk.TreeViewColumn col_name = new Gtk.TreeViewColumn.with_attributes("Name", name_renderer, "text", 0, null);

        places_data.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        places_filter.set_visible_column(2);
        places_view.enable_search = true;
        places_view.search_column = 0;
        places_view.set_headers_visible(false);
        name_renderer.editing_canceled.connect(() =>
        {
            name_renderer.editable = false;
        });
        name_renderer.edited.connect((path, text) =>
        {
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
        places_view.insert_column(col_name, -1);
        SimpleActionGroup branch_group = new SimpleActionGroup();
        SimpleAction act_hide = new SimpleAction("hide", null);
        act_hide.set_enabled(true);
        act_hide.activate.connect(() =>
        {
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
        act_rename.activate.connect(() =>
        {
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
        SimpleAction act_new = new SimpleAction("add", null);
        act_new.set_enabled(true);
        act_new.activate.connect(() =>
        {
            Gtk.TreePath path = null;
            Gtk.TreeViewColumn column;
            places_view.get_cursor(out path, out column);
            if(path != null) {
                Gdk.Rectangle rect;
                places_view.get_cell_area(path, column, out rect);
                add_pop.set_pointing_to(rect);
                add_pop.show_all();
            }
        });
        branch_group.add_action(act_new);
        places_view.insert_action_group("branch", branch_group);
        GLib.Menu places_menu_model = new GLib.Menu();
        places_menu_model.append("Hide Branch", "branch.hide");
        places_menu_model.append("Rename Branch", "branch.rename");
        places_menu_model.append("New Folder", "branch.add");
        places_menu = new Gtk.Menu.from_model(places_menu_model);
        places_menu.attach_to_widget(places_view, null);
        places_view.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
    }

    private void connect_signals()
    {
        this.destroy.connect(on_exit);

        main_stack.size_allocate.connect(resizeView);
        errorbar.response.connect(respond);

        undobutton.clicked.connect(() =>
        {
            App.undo_list.undo();
            if(App.undo_list.previous_count == 0)
                undobutton.set_sensitive(false);
            redobutton.set_sensitive(true);
        });
        redobutton.clicked.connect(() =>
        {
            App.undo_list.redo();
            if(App.undo_list.next_count == 0)
                redobutton.set_sensitive(false);
            undobutton.set_sensitive(true);
        });
        openbutton.clicked.connect(() => {open_pop.show_all();});
        open_pop.file_chosen.connect((file) => { addDir(file, null); });
        nextbutton.clicked.connect(() => { go_next(); });
        backbutton.clicked.connect(() => { go_prev(); });
        skipbutton.clicked.connect(loadFile);
        deletebutton.clicked.connect(removeFile);
        batchbutton.toggled.connect(swapBatch);

        search.search_changed.connect(() =>
        {
            traversal_filter.begin(search.text);
        });
        search.activate.connect(() =>
        {
            Gtk.TreePath path = null;
            Gtk.TreeViewColumn column;
            places_view.get_cursor(out path, out column);
            if(path != null)
                places_view.row_activated(path, column);
        });
        places_view.row_activated.connect((path, column) =>
        {
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

            search.grab_focus();
        });
        places_view.button_press_event.connect((event) =>
        {
            TreePath? path;
            places_view.get_cursor(out path, null);
            if(event.button == 3 && path != null) {
                places_view.popup_menu();
            }
            return false;
        });
        places_view.popup_menu.connect(() =>
        {
            places_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            return false;
        });
        places_view.set_search_equal_func((model, column, key, iter) =>
        {
            string name = "";
            model.get(iter, 0, out name);
            return !name.down().contains(key.down());
        });

        add_pop.file_created.connect(build_directory);

        target_pop.file_chosen.connect((file) => {
            App.item_list.load_folder(file);
            undobutton.set_sensitive(false);
            redobutton.set_sensitive(false);
            loadFile();
        });
    }

    private void add_actions()
    {
        GLib.SimpleAction new_action = new GLib.SimpleAction("new", null);
        new_action.activate.connect(() =>
        {
            target_pop.show_all();
        });

        GLib.SimpleAction settings_action = new GLib.SimpleAction("settings", null);
        settings_action.activate.connect(() =>
        {
            settings.sync();
            mode_stack.set_visible_child(settings);
            settings_action.set_enabled(false);
            main_box.show_all();
        });

        settings.done.connect(() =>
        {
            mode_stack.set_visible_child(main_paned);
            settings_action.set_enabled(true);
        });

        this.add_action(new_action);
        this.add_action(settings_action);
    }

    private void init_menus()
    {
        main_menu = new GLib.Menu();
        GLib.MenuItem new_item = new GLib.MenuItem("Sort New", "win.new");
        main_menu.append_item(new_item);
        GLib.MenuItem settings_item = new GLib.MenuItem("Settings", "win.settings");
        main_menu.append_item(settings_item);

        menubutton.set_menu_model(main_menu);
    }
    
    void respond (int response_id)
    {
        if(response_id == 1)
            replaceFile();
        if(response_id == 2)
            removeFile();
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
        }
    }

    private inline View current_view()
    {
        return (View)main_stack.get_visible_child();
    }
    
    public void resizeView()
    {
        current_view().resize();
    }

    public void go_next()
    {
        ++selected;
        toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view().load(App.to_display[selected]);
        current_view().display();
        backbutton.sensitive = true;
        if(selected >= App.to_display.size - 1) {
            nextbutton.sensitive = false;
        }
        this.show_all();
    }

    public void go_prev()
    {
        --selected;
        toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view().load(App.to_display[selected]);
        current_view().display();
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
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
        }
        if(App.item_list.is_empty()) {
            toolbar.set_subtitle("Completion: " + (App.item_list.orig_size - App.item_list.size).to_string() + "/" + App.item_list.orig_size.to_string());
            if(App.undo_list.previous_count > 0)
                undobutton.set_sensitive(true);
            redobutton.set_sensitive(App.undo_list.next_count > 0);
            main_stack.set_visible_child_name("empty");
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
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
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
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
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
        if(App.to_display.size > 1) {
            nextbutton.sensitive = true;
        }
        chosen_view.unload();
        if(App.to_display.is_empty) {
            main_stack.set_visible_child_name("empty");
            toolbar.set_subtitle("");
        } else {
            toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
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
            main_stack.set_visible_child(chosen_view);
            chosen_view.display();
        }
    }

    public void resetView()
    {
        if(selected >= App.to_display.size)
            selected = App.to_display.size - 1;
        toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view().load(App.to_display[selected]);
        current_view().display();
        if(selected >= App.to_display.size - 1) {
            nextbutton.sensitive = false;
        }
        if(selected <= 0) {
            backbutton.sensitive = false;
        }
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
        main_box.pack_end(errorbar, false, false);
        failed_last = true;
        failure_list = err;
        // TODO: Display errors
        show_all();
    }

    public void move_failed_single(string dest)
    {
        main_box.pack_end(errorbar, false, false);
        failed_last = true;
        failure_list = Motion();
        failure_list.new_position = new ArrayList<File>();
        failure_list.old_folder = new ArrayList<string>();
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
        if(!places_data.get_iter_first(out iter))
            return;
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
