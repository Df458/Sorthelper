using GLib;
using Gee;
namespace SortHelper{
public class MainWindow : Gtk.Window{
	private Gtk.Box container1;
	private Gtk.Toolbar toolbar;
	private Gtk.SeparatorToolItem separator;
	private Granite.Widgets.ThinPaned panedview;
	private Granite.Widgets.SourceList places;
	private Gtk.Menu settings;
	public Gtk.Image dispimage;
	public Gtk.Image datimage;
	private Gtk.ToolButton skipbutton;
	private Gtk.ToolButton deletebutton;
	private Gtk.ToolButton batchbutton;
	private GLib.Rand random;
	public ArrayList<string> list;
	private Gtk.ScrolledWindow scrollview;
	private DirItem libitem;
	private DirItem lib2item;
	private DirItem lib3item;
	public string current_image_location;
	public File current_file;
	public ImageFullView fullview;
	
	public MainWindow(){
		list = new ArrayList<string>();
	}
	
	private void create_widgets(){
		settings = new Gtk.Menu();
		toolbar = new Gtk.Toolbar();
		separator = new Gtk.SeparatorToolItem();
		panedview = new Granite.Widgets.ThinPaned();
		skipbutton = new Gtk.ToolButton(null, "skip");
		batchbutton = new Gtk.ToolButton(null, "Disable batch mode");
		deletebutton = new Gtk.ToolButton.from_stock(Gtk.Stock.DELETE);
		dispimage = new Gtk.Image();
		datimage = new Gtk.Image();
		scrollview = new Gtk.ScrolledWindow(null, null);
		fullview = new ImageFullView();
		places = new Granite.Widgets.SourceList();
		places.set_hexpand(false);
		places.set_sort_func(compareItems);
		
		libitem = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.lib"));
		lib2item = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.l2"));
		lib3item = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.l3"));
		
		//panedview.set_vexpand(true);
		scrollview.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		scrollview.set_hexpand(true);
		dispimage.set_vexpand(true);
		
		skipbutton.clicked.connect(loadImage);
		deletebutton.clicked.connect(removeImage);
		batchbutton.clicked.connect(swapBatch);
		
		separator.set_expand(true);
		
		toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		
		toolbar.insert(skipbutton, 0);
		toolbar.insert(batchbutton, 1);
		toolbar.insert(separator, 2);
		toolbar.insert(deletebutton, 3);
		toolbar.insert (App.instance.create_appmenu (settings), 4);
		
		places.root.add(libitem.UIElement);
		places.root.add(lib2item.UIElement);
		places.root.add(lib3item.UIElement);
		
		
		panedview.pack1(places, false, true);
		panedview.pack2(fullview, true, true);
		//panedview.pack2(scrollview, true, true);
		panedview.size_allocate.connect(resizeView);
		scrollview.add_with_viewport(dispimage);
		
		container1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		container1.set_homogeneous(false);
		
		container1.pack_start(toolbar, false, false, 0);
		container1.pack_start(panedview, false, false, 1);
		
		container1.set_child_packing(panedview, true, true, 0, Gtk.PackType.END);
		
		this.add(container1);
		
		container1.show_all();
	}
	
	public void resizeView() {
		dispimage.set_from_pixbuf(resizeImage(datimage).get_pixbuf());
	}
	
	public void loadImage() {
		datimage.set_from_pixbuf(getImage().get_pixbuf());
		resizeView();
		fullview.resetPage();
	}
	
	public void swapBatch() {
		App.batch_mode = !App.batch_mode;
		batchbutton.set_label(App.batch_mode ? "Disable batch mode" : "Enable batch mode");
	}
	
	public void removeImage() {
		if(App.batch_mode)
			while(App.to_display.size > 0) {
				App.to_display[0].delete();
				App.item_list.remove(App.to_display[0]);
				App.to_display.remove_at(0);
			}
		else {
			App.to_display[fullview.image_id].delete();
			App.item_list.remove(App.to_display[fullview.image_id]);
			App.to_display.remove_at(fullview.image_id);
		}
		if(App.to_display.size == 0) {
			loadImage();
		} else {
			fullview.resetPage();
		}
	}
	
	public Gtk.Image resizeImage(Gtk.Image imagedat){
		Gtk.Image image = new Gtk.Image();
		int oldwidth = imagedat.get_pixbuf().get_width();
		int oldheight = imagedat.get_pixbuf().get_height();
		int width = this.scrollview.get_allocated_width();
		int height = this.scrollview.get_allocated_height();
		if(oldwidth < width && oldheight < height){
			width = oldwidth;
			height = oldheight;
		}else{
			float wdiff = (float)width / (float)oldwidth;
			float hdiff = (float)height / (float)oldheight;
			if(wdiff > hdiff){
				width = (int)(oldwidth * hdiff);
				height = (int)(oldheight * hdiff);
			}else{
				width = (int)(oldwidth * wdiff);
				height = (int)(oldheight * wdiff);
			}
		}
		if(width <= 0 || height <= 0)
			return imagedat;
		image.set_from_pixbuf(imagedat.get_pixbuf().scale_simple(width, height, Gdk.InterpType.BILINEAR));
		return image;
	}
	
	public static int compareItems(Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b){
		if(a.name > b.name)
			return 1;
		else if(b.name > a.name)
			return -1;
		return 0;
	}
	
	private inline void setup_properties(){
		this.window_position = Gtk.WindowPosition.CENTER;
		this.set_default_size (800, 600);
		this.set_title("SortHelper");
		this.destroy.connect(on_exit);
	}
	
	public void build_all(){
		setup_properties();
		random = new GLib.Rand();
		create_widgets();
	}
	
	public Gtk.Image getImage(){
		Gtk.Image image = new Gtk.Image();
		bool worked = false;
		int attempts = 0;
		do{
//			App.to_display = App.item_list.getFilesByCount();
			App.to_display = App.item_list.getFilesByExpansion(App.item_list.getFilesByCount()[0]);
			attempts++;
			current_image_location = "/home/df458/Downloads/.dl/" + App.to_display[0].get_basename();
			try{
				Gdk.Pixbuf buf = new Gdk.Pixbuf.from_file(current_image_location);
				image.set_from_pixbuf(buf);
			}catch(GLib.Error e){
				stderr.printf(e.message);
				worked = false;
				continue;
			}
			worked = true;
		}while(!worked && attempts < 1000);
		if(attempts >= 1000)
			stderr.printf("Failed too many times, giving up...");
		else
			stderr.printf ("Loaded " + current_image_location + "\n");
		return image;
	}
	
	private void on_exit(){
		//Nothing yet
	}
}
}
