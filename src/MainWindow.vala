using GLib;
using Gee;
namespace SortHelper
{
public class MainWindow : Gtk.Window
{
    public Gtk.Box container1;
    private Gtk.HeaderBar toolbar;
    private Gtk.SeparatorToolItem separator;
    private Granite.Widgets.ThinPaned panedview;
    private Granite.Widgets.SourceList places;
    private BaseItem default_item;
    private BaseItem user_item;
    private Gtk.Menu settings;
    public Gtk.Image dispimage;
    public Gtk.Image datimage;
    private Gtk.ToolButton skipbutton;
    private Gtk.ToolButton deletebutton;
    private Gtk.ToggleToolButton batchbutton;
    private Gtk.ToolButton refreshbutton;
    private Gtk.ToolButton addbutton;
    private Gtk.ToolButton openbutton;
    private Gtk.ToolButton undobutton;
    private Gtk.ToolButton redobutton;
    private Gtk.ToolButton errorbutton;
    private Gtk.Popover open_pop;
    private Gtk.Spinner spinner;
    private GLib.Rand random;
    public ArrayList<string> list;
    private Gtk.ScrolledWindow scrollview;
    private DirItem libitem;
    private DirDialog dialog;
    public string current_image_location;
    public File current_file;
    public Gtk.InfoBar errorbar;
    public Gtk.FileChooserButton folder_selector;
    public Gtk.Button folder_button;

    public ImageFullView fullview;
    public VideoView vidview;
    public EmptyView empty_view;
    public DefaultView default_view;
    public AudioView audio_view;
    public WebView web_view;

    public Gtk.SearchEntry search;
    public Gtk.Box list_box;
    public Gtk.AccelGroup accel;
    private Gtk.Widget current_view;
    private View chosen_view;

    public bool filtering = false;
    public bool filterreset = false;
    private Motion failure_list;
    private bool failed_last = false;
    
    public MainWindow()
    {
        list = new ArrayList<string>();
    }
    
    private void create_widgets()
    {
        toolbar = new Gtk.HeaderBar();
        toolbar.set_title("Sorthelper");
        toolbar.set_subtitle("Completion: ");
        toolbar.set_show_close_button(true);
        this.set_titlebar(toolbar);
        settings = new Gtk.Menu();
        separator = new Gtk.SeparatorToolItem();
        panedview = new Granite.Widgets.ThinPaned();
        skipbutton = new Gtk.ToolButton(null, "skip");
        batchbutton = new Gtk.ToggleToolButton();
        batchbutton.set_label("Batch Mode");
        batchbutton.set_active (true);
        search = new Gtk.SearchEntry();
        list_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);

        dialog = new DirDialog(this);

        deletebutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-delete", Gtk.IconSize.SMALL_TOOLBAR), "Delete");
        refreshbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("view-refresh", Gtk.IconSize.SMALL_TOOLBAR), "Refresh");
        addbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("list-add", Gtk.IconSize.SMALL_TOOLBAR), "Add");
        openbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("document-open", Gtk.IconSize.SMALL_TOOLBAR), "Open");
        undobutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-undo", Gtk.IconSize.SMALL_TOOLBAR), "Undo");
        redobutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("edit-redo", Gtk.IconSize.SMALL_TOOLBAR), "Redo");
        errorbutton = new Gtk.ToolButton(new Gtk.Image.from_icon_name("emblem-important", Gtk.IconSize.SMALL_TOOLBAR), "Check Other");
        skipbutton.add_accelerator("clicked", accel, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        undobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        undobutton.set_sensitive(false);
        redobutton.add_accelerator("clicked", accel, 'z', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        redobutton.set_sensitive(false);
        errorbutton.set_sensitive(false);
        dispimage = new Gtk.Image();
        datimage = new Gtk.Image();
        scrollview = new Gtk.ScrolledWindow(null, null);
        
        fullview = new ImageFullView();
        default_view = new DefaultView();
        empty_view = new EmptyView();
        audio_view = new AudioView();
        vidview = new VideoView();
        web_view = new WebView();
        chosen_view = empty_view;

        places = new Granite.Widgets.SourceList();
        default_item = new BaseItem("default");
        user_item = new BaseItem("user");
        places.root.add(default_item);
        places.root.add(user_item);
        spinner = new Gtk.Spinner();
        places.set_hexpand(false);
        errorbar = new Gtk.InfoBar.with_buttons("Replace", 1, "Delete", 2);
        errorbar.set_show_close_button(true);
        errorbar.set_response_sensitive(1, true);
        errorbar.set_response_sensitive(2, true);
        errorbar.set_message_type(Gtk.MessageType.ERROR);
        Gtk.Container content = errorbar.get_content_area();
        content.add (new Gtk.Label("A file with the same name already exists!"));
        set_events(Gdk.EventMask.ALL_EVENTS_MASK);

        folder_selector = new Gtk.FileChooserButton("Add a Folder", Gtk.FileChooserAction.SELECT_FOLDER);
        folder_button = new Gtk.Button.with_label("Add...");
        folder_button.clicked.connect(() => {
            addDir(folder_selector.get_file());
            open_pop.hide();
        });
        open_pop = new Gtk.Popover(openbutton);
        Gtk.Box pop_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        pop_box.pack_start(folder_selector);
        pop_box.pack_start(folder_button);
        open_pop.child = pop_box;
        
        loadDirItems();
        places.set_filter_func(this.itemFilter, true);
        //places.button_release_event.connect((button) => { if(button.button == 3) places_rclick(); return false;});
        
        //panedview.set_vexpand(true);
        scrollview.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrollview.set_hexpand(true);
        dispimage.set_vexpand(true);
        
        skipbutton.clicked.connect(loadFile);
        deletebutton.clicked.connect(removeFile);
        batchbutton.toggled.connect(swapBatch);
        refreshbutton.clicked.connect(loadDirItems);
        openbutton.clicked.connect(() => {
            open_pop.show_all();
        });
        addbutton.clicked.connect(()=>{dialog.show_all();});
        undobutton.clicked.connect(()=>{
            App.undo_list.undo();
            if(App.undo_list.previous_count == 0)
                undobutton.set_sensitive(false);
            redobutton.set_sensitive(true);
        });
        redobutton.clicked.connect(()=>{
            App.undo_list.redo();
            if(App.undo_list.next_count == 0)
                redobutton.set_sensitive(false);
            undobutton.set_sensitive(true);
        });
        //errorbar.close.connect(error_cancel);
        errorbar.response.connect(respond);
        search.set_placeholder_text("Filter...");
        search.search_changed.connect(() => {
            filterreset = (search.get_text_length() == 0);
            filtering = !filterreset;
            places.refilter();
            if(filterreset) {
                default_item.collapse_all();
                user_item.collapse_all();
            } else {
                default_item.expand_all();
                user_item.expand_all();
            }
            filterreset = false;
        });
        //search.search_changed.connect(() => {libitem.has(search.text);});
        
        separator.set_expand(true);
        
        //toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

        list_box.pack_start(search, false, false);
        list_box.pack_start(places, true, true);
        
        toolbar.pack_start(skipbutton);
        toolbar.pack_start(batchbutton);
        toolbar.pack_end(openbutton);
        toolbar.pack_end(addbutton);
        toolbar.pack_end(refreshbutton);
        toolbar.pack_end(deletebutton);
        toolbar.pack_end(redobutton);
        toolbar.pack_end(undobutton);
        toolbar.pack_end(errorbutton);
        Gtk.ToolItem item = new Gtk.ToolItem();
        item.add(spinner);
        toolbar.pack_end (/*App.instance.create_appmenu (settings)*/item);
        
        panedview.pack1(list_box, false, true);
        panedview.pack2(fullview, true, true);
        //panedview.pack2(scrollview, true, true);
        panedview.size_allocate.connect(resizeView);
        panedview.set_position(200);
        scrollview.add_with_viewport(dispimage);

        current_view = fullview;
        
        container1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        container1.set_homogeneous(false);
        
        //container1.pack_start(toolbar, false, false);
        container1.pack_end(panedview, false, false);
        //container1.pack_end(errorbar, false, false);
        
        container1.set_child_packing(panedview, true, true, 0, Gtk.PackType.END);
        
        this.add(container1);
        
        this.show_all();
    }
    
    void respond (int response_id)
    {
        //stderr.printf("Clicked: %d", response_id);
        
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
        default_item.clear();
        libitem = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.lib"));
        default_item.add(libitem);
        libitem.expand_with_parents();
    }
    
    public void resizeView()
    {
        //dispimage.set_from_pixbuf(resizeImage(datimage).get_pixbuf());
    }
    
    public void loadFile()
    {
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

        spinner.start();
        getFiles.begin((obj, res) => {
            display_files();
            spinner.stop();
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
            //stderr.printf("ID: %d / %d", fullview.image_id, App.to_display.size);
            if(fullview.image_id >= App.to_display.size)
                fullview.image_id--;
            //stderr.printf("NEW ID: %d / %d", fullview.image_id, App.to_display.size);
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
            //stderr.printf("ID: %d / %d", fullview.image_id, App.to_display.size);
            if(fullview.image_id >= App.to_display.size)
                fullview.image_id--;
            //stderr.printf("NEW ID: %d / %d", fullview.image_id, App.to_display.size);
        }
        if(App.to_display.size == 0) {
            loadFile();
        } else {
            resetView();
        }
    }
    
    private inline void setup_properties()
    {
        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.set_title("SortHelper");
        this.destroy.connect(on_exit);
        accel = new Gtk.AccelGroup();
        this.add_accel_group(accel);
    }
    
    public void build_all()
    {
        setup_properties();
        random = new GLib.Rand();
        create_widgets();
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
        chosen_view.unload();
        if(App.to_display.is_empty)
            set_content(empty_view);
        else {
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
            chosen_view.load();
            set_content(chosen_view);
            chosen_view.display();
        }
    }

    public void resetView()
    {
        chosen_view.fileRemoved();
    }

    public void set_content(Gtk.Widget widget)
    {
        int pos = panedview.get_position();
        panedview.remove(current_view);
        panedview.set_position(0);
        panedview.pack2(widget, true, false);
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
        failure_list = new Motion();
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

    public void addDir(File f)
    {
        user_item.add(new DirItem.FromFile(f));
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
}
}
