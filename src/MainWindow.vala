using Gee;
using Gtk;
namespace SortHelper
{
[GtkTemplate (ui = "/org/df458/sorthelper/MainWindow.ui")]
public class MainWindow : ApplicationWindow
{
    private     Rand random;
    private     AccelGroup accel;
    public int  selected = 0;
    public File current_file;

    [GtkChild]
    private HeaderBar toolbar;

    [GtkChild]
    private Paned main_paned;
    [GtkChild]
    private Box   main_box;
    [GtkChild]
    private Box   view_box;
    [GtkChild]
    private Stack main_stack;
    private Stack secondary_stack;
    [GtkChild]
    private Stack mode_stack;

    [GtkChild]
    private MenuButton   menubutton;
    [GtkChild]
    private Button       undobutton;
    [GtkChild]
    private Button       redobutton;
    [GtkChild]
    private Button       nextbutton;
    [GtkChild]
    private Button       backbutton;
    [GtkChild]
    private Button       deletebutton;

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

    private SettingsPane  settings;

    [GtkChild]
    private InfoBar errorbar;

    [GtkChild]
    private SearchEntry     search;
    [GtkChild]
    private TreeView        places_view;
    [GtkChild]
    private TreeStore       places_data;
    [GtkChild]
    private TreeModelFilter places_filter;
    [GtkChild]
    private CellRendererText name_renderer;
    [GtkChild]
    private TreeViewColumn col_name;

    private AddFolderPopover  add_pop;

    private string filter_key;
    private bool   filtering = false;
    private bool   filterreset = false;

    /* private GLib.Menu main_menu; */
    private Gtk.Menu places_menu;

    construct {
        back_action = new SimpleAction ("prev", null);
        back_action.activate.connect(go_prev);
        add_action(back_action);

        next_action = new SimpleAction ("next", null);
        next_action.activate.connect(go_next);
        add_action(next_action);

        skip_action = new SimpleAction ("skip", null);
        skip_action.activate.connect(skip);
        add_action(skip_action);

        var open_folder_action = new SimpleAction ("open_folder", null);
        open_folder_action.activate.connect(open_folder);
        add_action(open_folder_action);

        var new_action = new SimpleAction("new", null);
        new_action.activate.connect(sort_new);
        add_action(new_action);
    }
 
    public MainWindow()
    {
        random = new GLib.Rand();
        accel = new Gtk.AccelGroup();
        this.add_accel_group(accel);
        set_events(Gdk.EventMask.ALL_EVENTS_MASK);

        secondary_stack  = new Stack();
        settings         = new SettingsPane();
        secondary_stack.visible = false;
        mode_stack.add_named(settings, "settings");
        mode_stack.set_visible_child(main_paned);

        init_content();
        connect_signals();
        add_actions();

        this.show_all();
    }

    private void init_content()
    {
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

        places_view.set_search_entry(search);

        undobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        redobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        nextbutton.add_accelerator("clicked", accel, Gdk.Key.Right, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        backbutton.add_accelerator("clicked", accel, Gdk.Key.Left, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);

        main_stack.add_named(default_view, "default");
        main_stack.add_named(fullview,     "image");
        main_stack.add_named(empty_view,   "empty");
        main_stack.add_named(audio_view,   "audio");
        main_stack.add_named(vidview,      "video");
        main_stack.add_named(web_view,     "web");
        main_stack.add_named(archive_view, "archive");
        main_stack.add_named(comic_view,   "comic");
        main_stack.add_named(welcome_view, "welcome");
    }

    private void init_places_view()
    {
        add_pop        = new AddFolderPopover(places_view);

        places_data.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        places_filter.set_visible_column(2);

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

    private void open_folder() {
        var dlg = new FileChooserDialog("Add a sort directory", this, FileChooserAction.SELECT_FOLDER, "Add", ResponseType.ACCEPT, "Cancel", ResponseType.CANCEL);
        int response = dlg.run();
        dlg.close();
        if (response == ResponseType.ACCEPT) {
            addDir(dlg.get_file (), null);
        }
    }

    private void connect_signals()
    {
        places_view.set_search_equal_func((model, column, key, iter) =>
        {
            string name = "";
            model.get(iter, 0, out name);
            return !name.down().contains(key.down());
        });

        add_pop.file_created.connect(build_directory);
    }

    private void sort_new () {
        var dlg = new FileChooserDialog("Add a sort directory", this, FileChooserAction.SELECT_FOLDER, "Add", ResponseType.ACCEPT, "Cancel", ResponseType.CANCEL);
        int response = dlg.run();
        dlg.close();
        if (response == ResponseType.ACCEPT) {
            App.item_list.load_folder(dlg.get_file ());
            undobutton.set_sensitive(false);
            redobutton.set_sensitive(false);
            loadFile();
        }
    }

    private void add_actions()
    {
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

        this.add_action(settings_action);
    }
    
    [GtkCallback]
    private void respond (int response_id)
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
    
    [GtkCallback]
    private void resizeView()
    {
        current_view().resize();
    }

    public void go_next()
    {
        ++selected;
        toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view().load(App.to_display[selected]);
        current_view().display();
        back_action.set_enabled (true);
        next_action.set_enabled (selected < App.to_display.size - 1);
        this.show_all();
    }

    public void go_prev()
    {
        --selected;
        toolbar.set_subtitle(App.to_display[selected].get_basename() + (App.to_display.size > 1 ? " (" + (selected + 1).to_string() + "/" + App.to_display.size.to_string() + ")" : ""));
        current_view().load(App.to_display[selected]);
        current_view().display();
        next_action.set_enabled (true);
        if(selected <= 0) {
            back_action.set_enabled (false);
        }
        this.show_all();
    }
    
    public void loadFile()
    {
        selected = 0;
        back_action.set_enabled (false);
        next_action.set_enabled (false);
        search.grab_focus();
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
        }

        skip_action.set_enabled (!App.item_list.is_empty ());

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
    
    [GtkCallback]
    public void replaceFile()
    {
        search.grab_focus();
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
        }
        if(App.instance.batch_mode) {
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

    [GtkCallback]
    public void removeFile()
    {
        search.grab_focus();
        if(errorbar.get_parent() == main_box) {
            main_box.remove(errorbar);
            main_box.show_all();
        }
        if(App.instance.batch_mode) {
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
            next_action.set_enabled (true);
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
            next_action.set_enabled (false);
        }
        if(selected <= 0) {
            next_action.set_enabled (false);
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
        view_box.pack_start(secondary_stack, true, true);
        show_all();
    }
    
    [GtkCallback]
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

    private void skip () {
        foreach (File file in App.to_display) {
            App.item_list.remove (file);
        }

        loadFile ();
    }

    [GtkCallback]
    private void folder_cancel_edit()
    {
        name_renderer.editable = false;
    }

    [GtkCallback]
    private void folder_finish_edit(string path, string text)
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
    }

    [GtkCallback]
    private void on_undo()
    {
        App.undo_list.undo();
        if(App.undo_list.previous_count == 0)
            undobutton.set_sensitive(false);
        redobutton.set_sensitive(true);
    }

    [GtkCallback]
    private void on_redo()
    {
        App.undo_list.redo();
        if(App.undo_list.next_count == 0)
            redobutton.set_sensitive(false);
        undobutton.set_sensitive(true);
    }

    [GtkCallback]
    private void update_search()
    {
        traversal_filter.begin(search.text);
    }

    [GtkCallback]
    private void search_activate()
    {
        Gtk.TreePath path = null;
        Gtk.TreeViewColumn column;
        places_view.get_cursor(out path, out column);
        if(path != null)
            places_view.row_activated(path, column);
    }

    [GtkCallback]
    private void choose_folder(TreeView view, TreePath path, TreeViewColumn column)
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

        if(App.instance.batch_mode) {
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
    }

    [GtkCallback]
    private bool on_folder_click(Gdk.EventButton event)
    {
        TreePath? path;
        places_view.get_cursor(out path, null);
        if(event.button == 3 && path != null) {
            places_view.popup_menu();
        }
        return false;
    }

    [GtkCallback]
    private bool on_folder_popup()
    {
        places_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
        return false;
    }

    private SimpleAction back_action;
    private SimpleAction next_action;
    private SimpleAction skip_action;
}
}
