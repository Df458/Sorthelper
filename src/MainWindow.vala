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
	public Gtk.Image image;
	public Gtk.Image imagedat;
	private Gtk.ToolButton skipbutton;
	private GLib.Rand random;
	public ArrayList<string> list;
	private Gtk.ScrolledWindow scrollview;
	private DirItem libitem;
	private DirItem lib2item;
	private DirItem lib3item;
	public string current_image_location;
	
	public MainWindow(){
		list = new ArrayList<string>();
		try{
			var directory = File.new_for_path ("/home/df458/Downloads/.dl");

				var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

				FileInfo file_info;
				while ((file_info = enumerator.next_file ()) != null) {
				    list.add(file_info.get_name());
				}

			} catch (Error e) {
				stderr.printf ("Error: %s\n", e.message);
				return;
			}
			
	}
	
	private void create_widgets(){
		settings = new Gtk.Menu();
		toolbar = new Gtk.Toolbar();
		separator = new Gtk.SeparatorToolItem();
		panedview = new Granite.Widgets.ThinPaned();
		skipbutton = new Gtk.ToolButton(null, "skip");
		image = new Gtk.Image();
		imagedat = new Gtk.Image();
		scrollview = new Gtk.ScrolledWindow(null, null);
		places = new Granite.Widgets.SourceList();
		Granite.Widgets.SourceList.SortFunc sfunc = compareItems;
		places.set_sort_func(sfunc);
		//attr_item = new Granite.Widgets.SourceList.ExpandableItem("Attributes");
		//media_item = new Granite.Widgets.SourceList.ExpandableItem("Media");
		
		libitem = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.lib"));
		lib2item = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.l2"));
		lib3item = new DirItem.FromFile(File.new_for_path ("/home/df458/Documents/.Collections/.l3"));
		
		//panedview.set_vexpand(true);
		scrollview.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		image.set_vexpand(true);
		
		skipbutton.clicked.connect(getImage);
		
		separator.set_expand(true);
		
		toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		
		toolbar.insert(skipbutton, 0);
		toolbar.insert(separator, 1);
		toolbar.insert (App.instance.create_appmenu (settings), 2);
		
		places.root.add(libitem.UIElement);
		places.root.add(lib2item.UIElement);
		places.root.add(lib3item.UIElement);
		
		
		panedview.pack1(places, true, true);
		panedview.pack2(scrollview, true, true);
		panedview.size_allocate.connect(resizeImage);
		scrollview.add_with_viewport(image);
		
		container1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		container1.set_homogeneous(false);
		
		container1.pack_start(toolbar, false, false, 0);
		container1.pack_start(panedview, false, false, 1);
		
		container1.set_child_packing(panedview, true, true, 0, Gtk.PackType.END);
		
		this.add(container1);
		
		container1.show_all();
	}
	
	public void resizeImage(){
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
		
		this.image.set_from_pixbuf(imagedat.get_pixbuf().scale_simple(width, height, Gdk.InterpType.BILINEAR));
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
	
	public void getImage(){
		bool worked = false;
		int attempts = 0;
		do{
			attempts++;
			current_image_location = "/home/df458/Downloads/.dl/" + list[random.int_range(0, list.size - 1)];
			try{
				Gdk.Pixbuf buf = new Gdk.Pixbuf.from_file(current_image_location);
				imagedat.set_from_pixbuf(buf);
				resizeImage();
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
	}
	
	private void on_exit(){
		//Nothing yet
	}
}
}
