using GLib;
using Gee;
namespace SortHelper{
public class MainWindow : Gtk.Window{
    public Gtk.Box container1;
    private Gtk.HeaderBar toolbar;
    private Gtk.SeparatorToolItem separator;
    private Granite.Widgets.ThinPaned panedview;
    private Granite.Widgets.SourceList places;
    private Gtk.Menu settings;
    public Gtk.Image dispimage;
    public Gtk.Image datimage;
    private Gtk.ToolButton skipbutton;
    private Gtk.ToolButton deletebutton;
    private Gtk.ToggleToolButton batchbutton;
    private Gtk.ToolButton refreshbutton;
    private Gtk.ToolButton addbutton;
    private Gtk.Spinner spinner;
    private GLib.Rand random;
    public ArrayList<string> list;
    private Gtk.ScrolledWindow scrollview;
    private DirItem libitem;
    private DirDialog dialog;
    public string current_image_location;
    public File current_file;
    public Gtk.InfoBar errorbar;
    public ImageFullView fullview;
    public VideoView vidview;
    public Gtk.SearchEntry search;
    public Gtk.Box list_box;
    public Gtk.AccelGroup accel;
    private Gtk.Widget current_view;

    public bool filtering = false;
    public bool filterreset = false;
    
    public MainWindow(){
        list = new ArrayList<string>();
    }
    
    private void create_widgets(){
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
        skipbutton.add_accelerator("clicked", accel, 's', Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        deletebutton.add_accelerator("clicked", accel, 'd', Gdk.ModifierType.SHIFT_MASK | Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        dispimage = new Gtk.Image();
        datimage = new Gtk.Image();
        scrollview = new Gtk.ScrolledWindow(null, null);
        fullview = new ImageFullView();
        places = new Granite.Widgets.SourceList();
        spinner = new Gtk.Spinner();
        places.set_hexpand(false);
        errorbar = new Gtk.InfoBar.with_buttons("Replace", 1, "Delete", 2);
        errorbar.set_show_close_button(true);
        errorbar.set_response_sensitive(1, false);
        errorbar.set_response_sensitive(2, true);
        errorbar.set_message_type(Gtk.MessageType.ERROR);
        Gtk.Container content = errorbar.get_content_area();
        content.add (new Gtk.Label("A file with the same name already exists!"));
        vidview = new VideoView();
        
        loadDirItems();
        places.set_filter_func(this.itemFilter, true);
        
        //panedview.set_vexpand(true);
        scrollview.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrollview.set_hexpand(true);
        dispimage.set_vexpand(true);
        
        skipbutton.clicked.connect(loadFile);
        deletebutton.clicked.connect(removeFile);
        batchbutton.toggled.connect(swapBatch);
        refreshbutton.clicked.connect(loadDirItems);
        addbutton.clicked.connect(()=>{dialog.show_all();});
        //errorbar.close.connect(error_cancel);
        errorbar.response.connect(respond);
        search.set_placeholder_text("Filter...");
        search.search_changed.connect(() => {
            filterreset = (search.get_text_length() == 0);
            filtering = !filterreset;
            places.refilter();
            if(filterreset)
                places.root.collapse_all();
                //stdout.printf("search len: %d\n", search.get_text_length());
            else
                places.root.expand_all();
            filterreset = false;
        });
        //search.search_changed.connect(() => {libitem.has(search.text);});
        
        separator.set_expand(true);
        
        //toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

        list_box.pack_start(search, false, false);
        list_box.pack_start(places, true, true);
        
        toolbar.pack_start(skipbutton);
        toolbar.pack_start(batchbutton);
        toolbar.pack_end(addbutton);
        toolbar.pack_end(refreshbutton);
        toolbar.pack_end(deletebutton);
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
    
    void respond (int response_id) {
        //stderr.printf("Clicked: %d", response_id);
        
        if(response_id == 2)
            removeFile();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
    }
    
    public void loadDirItems() {
        places.root.clear();
        libitem = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.lib"));
        places.root.add(libitem);
        libitem.expand_with_parents();
    }
    
    public void resizeView() {
        //dispimage.set_from_pixbuf(resizeImage(datimage).get_pixbuf());
    }
    
    public void loadFile() {
        search.grab_focus();
        if(errorbar.get_parent() == container1) {
            container1.remove(errorbar);
            container1.show_all();
        }
        if(App.item_list.is_empty()) {
            return;
        }

        spinner.start();
        //getImage.begin((obj, res) => {
            //datimage.set_from_pixbuf(getImage.end(res).get_pixbuf());
            //resizeView();
            //fullview.resetPage();
            //spinner.stop();
            //toolbar.set_subtitle("Completion: " + (App.item_list.orig_size - App.item_list.size).to_string() + "/" + App.item_list.orig_size.to_string());
        //});


    }
    
    public void swapBatch() {
        App.batch_mode = batchbutton.get_active();
        //batchbutton.set_label(App.batch_mode ? "Disable batch mode" : "Enable batch mode");
    }
    
    public void removeFile() {
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
            fullview.image_id--;
        }
        if(App.to_display.size == 0) {
            loadFile();
        } else {
            fullview.resetPage();
        }
    }
    
    //public Gtk.Image resizeImage(Gtk.Image imagedat){
		////Gtk.Image image = new Gtk.Image();
		////int oldwidth = imagedat.get_pixbuf().get_width();
		////int oldheight = imagedat.get_pixbuf().get_height();
		////int width = this.scrollview.get_allocated_width();
		////int height = this.scrollview.get_allocated_height();
		////if(oldwidth < width && oldheight < height){
			////width = oldwidth;
			////height = oldheight;
		////}else{
			////float wdiff = (float)width / (float)oldwidth;
			////float hdiff = (float)height / (float)oldheight;
			////if(wdiff > hdiff){
				////width = (int)(oldwidth * hdiff);
				////height = (int)(oldheight * hdiff);
			////}else{
				////width = (int)(oldwidth * wdiff);
				////height = (int)(oldheight * wdiff);
			////}
		////}
		////if(width <= 0 || height <= 0)
			////return imagedat;
		////image.set_from_pixbuf(imagedat.get_pixbuf().scale_simple(width, height, Gdk.InterpType.BILINEAR));
		////return image;
	//return imagedat;
    //}
    
    private inline void setup_properties(){
        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.set_title("SortHelper");
        this.destroy.connect(on_exit);
        accel = new Gtk.AccelGroup();
        this.add_accel_group(accel);
    }
    
    public void build_all(){
        setup_properties();
        random = new GLib.Rand();
        create_widgets();
    }
    
    public async Gtk.Image getImage(){
        Gtk.Image image = new Gtk.Image();
        bool worked = false;
        int attempts = 0;
        do {
            File infile = App.item_list.getFilesByCount()[0];
    //			App.to_display = App.item_list.getFilesByCount();
            App.to_display = yield App.item_list.getFilesByExpansion(infile);
            
            attempts++;
            current_image_location = "/home/df458/Downloads/.dl/" + App.to_display[0].get_basename();
            try{
                Gdk.PixbufAnimation buf = new Gdk.PixbufAnimation.from_file(current_image_location);
                if(buf.is_static_image())
                    image.set_from_pixbuf(buf.get_static_image());
                else
                    image.set_from_animation(buf);
            }catch(GLib.Error e){
                stderr.printf(e.message);
                worked = false;
                continue;
            }
            worked = true;
        }while(!worked && attempts < 1000);
        if(attempts >= 1000) {
            stderr.printf("Failed too many times, giving up...");
        } else
            stderr.printf ("Loaded " + current_image_location + "\n");
        return image;
    }

    public void set_content(Gtk.Widget widget) {
        int pos = panedview.get_position();
        panedview.remove(current_view);
        panedview.set_position(0);
        panedview.pack2(widget, true, false);
        current_view = widget;
        panedview.set_position(pos);
        this.show_all();
    }

    public void build_directory(string name) {
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
    
    private void on_exit(){
	    //Nothing yet
    }

    public bool itemFilter(Granite.Widgets.SourceList.Item item) {
        //return true;
        return ((DirItem)item).has(search.text);
    }
}
}
