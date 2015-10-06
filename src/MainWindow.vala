using GLib;
using Gee;
namespace SortHelper
{
public class MainWindow : Gtk.Window
{
    public Gtk.Box container1;
    private Gtk.HeaderBar toolbar;
    private Granite.Widgets.ThinPaned panedview;
    private Granite.Widgets.SourceList places;
    private BaseItem default_item;
    private BaseItem user_item;
    private Gtk.ToolButton skipbutton;
    private Gtk.ToolButton deletebutton;
    private Gtk.ToggleToolButton batchbutton;
    private Gtk.ToolButton refreshbutton;
    private Gtk.ToolButton addbutton;
    private Gtk.ToolButton newbutton;
    private Gtk.ToolButton openbutton;
    private Gtk.ToolButton undobutton;
    private Gtk.ToolButton redobutton;
    private Gtk.ToolButton errorbutton;
    private Gtk.Button nextbutton;
    private Gtk.Button backbutton;
    private AddFolderPopover add_pop;
    private OpenFolderPopover open_pop;
    private OpenFolderPopover target_pop;
    private GLib.Rand random;
    public ArrayList<string> list;
    private DirItem libitem;
    public string current_image_location;
    public File current_file;
    public Gtk.InfoBar errorbar;
    private Gtk.ActionBar status_bar;
    private Gtk.Label file_label;
    public int selected = 0;

    public ImageFullView fullview;
    public VideoView vidview;
    public EmptyView empty_view;
    public DefaultView default_view;
    public AudioView audio_view;
    public WebView web_view;

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

    // Tree Shit
    private Gtk.TreeView places_view;
    private Gtk.TreeStore places_data;
    private Gtk.TreeModelFilter places_filter;
    private string filter_key;
 
    public MainWindow()
    {
        random = new GLib.Rand();
        list = new ArrayList<string>();
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

        current_view = default_view;
        chosen_view = empty_view;

        // Init Structural Widgets
        toolbar = new Gtk.HeaderBar();
        status_bar = new Gtk.ActionBar();
        panedview = new Granite.Widgets.ThinPaned();
        list_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        // TODO: Consider making errorbar a class as well
        errorbar = new Gtk.InfoBar.with_buttons("Replace", 1, "Delete", 2);
        Gtk.Container content = errorbar.get_content_area();
        container1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        places = new Granite.Widgets.SourceList();
        view_overlay = new Gtk.Overlay();
        control_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
        control_revealer = new Gtk.Revealer();
        Gtk.ScrolledWindow places_wrapper = new Gtk.ScrolledWindow(null, null);

        places_data = new Gtk.TreeStore(4, typeof(string), typeof(string), typeof(bool), typeof(bool));
        places_data.set_sort_column_id(0, Gtk.SortType.ASCENDING);
        places_filter = new Gtk.TreeModelFilter(places_data, null);
        places_filter.set_visible_column(2);
        //places_filter.set_visible_func((model, iter) => {
            //if(filter_key == null)
                //return true;
            //string name;
            //model.get(iter, 0, out name);
            //return name.down().contains(filter_key);
        //});
        places_view = new Gtk.TreeView.with_model(places_filter);
        //places_view.enable_search = true;
        //places_view.search_column = 0;
        places_view.set_headers_visible(false);
        Gtk.TreeViewColumn col_name = new Gtk.TreeViewColumn.with_attributes("Name", new Gtk.CellRendererText(), "text", 0, null);
        places_view.insert_column(col_name, -1);
        places_view.cursor_changed.connect(() => {
            if(search.text == "") {
                Gtk.TreePath path;
                places_view.get_cursor(out path, null);
                if(places_view.is_row_expanded(path))
                    places_view.collapse_row(path);
                else
                    places_view.expand_row(path, false);
                Gtk.TreeIter iter;
                places_data.get_iter(out iter, path);
                places_data.set(iter, 3, places_view.is_row_expanded(path));
            }
        });
        places_view.row_expanded.connect((iter, path) => {
            if(search.text == "")
                places_data.set(iter, 3, true);
        });
        places_view.row_collapsed.connect((iter, path) => {
            if(search.text == "")
                places_data.set(iter, 3, false);
        });
        places_view.row_activated.connect((path, column) => {
            Gtk.TreeIter iter;
            places_data.get_iter(out iter, path);
            string move_path = "";
            places_data.get(iter, 1, &move_path);

            if(App.batch_mode)
                App.move_files(move_path, list);
            else
                App.move_file(move_path, list[selected]);
        });
        //places_view.set_search_equal_func((model, col, key, iter) =>{
            //string name;
            //model.get(iter, col, out name);
            //return name.down().contains(key.down()) == false;
        //});

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
        places.set_filter_func(this.itemFilter, true);
        view_overlay.set_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        view_overlay.motion_notify_event.connect(() => {
                if(nextbutton.sensitive || backbutton.sensitive)
                    control_revealer.set_reveal_child(true);
                if(has_last_motion)
                    Source.remove(last_motion_timer);
                last_motion_timer = Timeout.add_seconds(3, () =>{
                        control_revealer.set_reveal_child(false);
                        has_last_motion = false;
                        return false;
                        });
                has_last_motion = true;
                return false;
                });
        view_overlay.leave_notify_event.connect(() => {
                control_revealer.set_reveal_child(false);
                if(has_last_motion)
                    Source.remove(last_motion_timer);
                has_last_motion = false;
                return false;
                });
        control_box.valign = Gtk.Align.CENTER;

        // Init Display Widgets
        skipbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-next-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Skip");
        deletebutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Delete");
        refreshbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("view-refresh-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Refresh");
        newbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("document-new-symbolic", Gtk.IconSize.MENU), "New");
        target_pop = new OpenFolderPopover(newbutton);
        addbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("folder-new-symbolic", Gtk.IconSize.MENU), "Add");
        add_pop = new AddFolderPopover(addbutton);
        openbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("folder-open-symbolic", Gtk.IconSize.MENU), "Open");
        open_pop = new OpenFolderPopover(openbutton);
        undobutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-undo-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Undo");
        redobutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-redo-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Redo");
        errorbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("emblem-important-symbolic", Gtk.IconSize.SMALL_TOOLBAR), "Check Other");

        //Gtk.CssProvider css = new Gtk.CssProvider();
        //css.parsing_error.connect((sec,err)=>{stderr.printf("CSS PARSE ERROR: %s\n", err.message);});
        //string css_str = "GtkButton.test { background-image: none; background-color: #ff0000;}";
        //css.load_from_data(css_str, -1);
        nextbutton = new Gtk.Button.from_icon_name("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        nextbutton.get_style_context().add_class("test");
        backbutton = new Gtk.Button.from_icon_name("go-previous-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        backbutton.get_style_context().add_class("test");
        batchbutton = new Gtk.ToggleToolButton();
        file_label = new Gtk.Label("Stuff goes here");
        search = new Gtk.SearchEntry();
        default_item = new BaseItem("default");
        user_item = new BaseItem("user");

        skipbutton.add_accelerator("clicked", accel, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        skipbutton.clicked.connect(loadFile);
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.clicked.connect(removeFile);
        refreshbutton.clicked.connect(loadDirItems);
        newbutton.clicked.connect(() => {target_pop.show_all();});
        addbutton.clicked.connect(() => {add_pop.show_all();});
        openbutton.clicked.connect(() => {open_pop.show_all();});
        add_pop.file_created.connect(build_directory);
        open_pop.file_chosen.connect((name) => {
            //addDir(new File.new_for_path(name));
            // TODO: Reimplement this
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
        backbutton.clicked.connect(() => { go_prev(); });
        backbutton.halign = Gtk.Align.START;
        backbutton.valign = Gtk.Align.CENTER;
        backbutton.margin = 10;
        batchbutton.set_label("Batch Mode");
        batchbutton.set_icon_widget(new Gtk.Image.from_icon_name("edit-select-all", Gtk.IconSize.SMALL_TOOLBAR));
        batchbutton.set_active (true);
        batchbutton.toggled.connect(swapBatch);

        search.set_placeholder_text("Filter...");
        search.search_changed.connect(() => {
            //filterreset = (search.get_text_length() == 0);
            //filtering = !filterreset;
            //places.refilter();
                //filter_key = search.text.down();
                //places_filter.refilter();
            traversal_filter.begin(search.text);
            //if(filterreset) {
                //default_item.collapse_all();
                //user_item.collapse_all();
                //default_item.expand_with_parents();
                //user_item.expand_with_parents();
            //} else {
                //default_item.expand_all();
                //user_item.expand_all();
            //}
            //filterreset = false;
        });

        default_item.expand_all();
        user_item.expand_all();

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

        places.root.add(default_item);
        places.root.add(user_item);

        list_box.pack_start(search, false, false);
        places_wrapper.add(places_view);
        list_box.pack_start(places_wrapper, true, true);
        status_bar.set_center_widget(file_label);
        status_bar.pack_start(addbutton);
        status_bar.pack_start(openbutton);
        status_bar.pack_start(refreshbutton);

        panedview.pack1(list_box, false, true);
        panedview.pack2(view_overlay, true, true);
        container1.pack_end(status_bar, false, false);
        container1.pack_end(panedview, true, true);

        this.add(container1);
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
        if(App.to_display.size > 1) {
            nextbutton.sensitive = true;
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
                stdout.printf("Got type: %s\n", filetype);
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
        DirItem selected = (DirItem)places.selected;
        if(selected == null)
            return;

        try {
            File directory = File.new_for_path(selected.owned_directory.get_path() + "/" + name);
            directory.make_directory();
            selected.add(new DirItem.FromFile(directory));
        } catch(Error e) {
            stderr.printf("Error creating directory: %s\n", e.message);
        }
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

    public void places_rclick()
    {
        //sidebar_right_click_pop.relative_to = item;
        //sidebar_right_click_pop.show();
        //if(places.selected == null)
            //return;
        //Gtk.Menu menu = places.selected.get_context_menu();
        //menu.attach_to_widget(places, null);
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
                if(key.length == 0 && expanded)
                    places_view.expand_row(places_data.get_path(iter), false);
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
