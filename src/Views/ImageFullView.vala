using GLib;
using Gee;
namespace SortHelper{
public class ImageFullView : View, Gtk.VBox{
    private Gtk.Toolbar toolbar;
    private Gtk.ScrolledWindow scroll_view;
    public int image_id = 0;
    private Gtk.Image dispimage;
    private Gtk.Image datimage;
    private Gtk.ToolButton next_button;
    private Gtk.ToolButton back_button;
    private Gtk.SeparatorToolItem separator;
    private Gtk.Label count_label;
    private Gtk.SeparatorToolItem separator_r;
    
    public ImageFullView() {
        this.set_homogeneous(false);
        scroll_view = new Gtk.ScrolledWindow(null, null);
        dispimage = new Gtk.Image();
        scroll_view.add_with_viewport(dispimage);
        separator = new Gtk.SeparatorToolItem();
        separator.set_expand(true);
        separator_r = new Gtk.SeparatorToolItem();
        separator_r.set_expand(true);
        next_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-next", Gtk.IconSize.SMALL_TOOLBAR), "Next");
        next_button.clicked.connect(() => {
            if(image_id < App.to_display.size - 1) {
            image_id++;
            loadImage();
            }
        });
        back_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-previous", Gtk.IconSize.SMALL_TOOLBAR), "Previous");
        back_button.clicked.connect(() => {
            if(image_id > 0) {
            image_id--;
            loadImage();
            }
        });
        toolbar = new Gtk.Toolbar();
        toolbar.insert(back_button, 0);
        toolbar.insert(separator, 1);
        Gtk.ToolItem item = new Gtk.ToolItem();
        count_label = new Gtk.Label("Image");
        item.add(count_label);
        toolbar.insert(item, 2);
        toolbar.insert(separator_r, 3);
        toolbar.insert(next_button, 4);
        this.pack_start(toolbar, false, false, 0);
        this.pack_start(scroll_view, true, true, 1);
    }
    
    public void resetPage() {
	    image_id = 0;
	    loadImage();
    }
    
    public void resize() {
	    dispimage.set_from_pixbuf(resizeImage(datimage).get_pixbuf());
    }
    
    public void loadImage() {
	    datimage = getImage();
	    resize();
	    next_button.set_sensitive(image_id < App.to_display.size - 1);
	    back_button.set_sensitive(image_id > 0);
	    count_label.label = App.to_display[image_id].get_basename();
	    if(App.to_display.size > 1) {
		    count_label.label += " (" + (image_id+1).to_string() + "/" + App.to_display.size.to_string() + ")";
	    }
    }
    
    public Gtk.Image resizeImage(Gtk.Image imagedat){
	    Gtk.Image image = new Gtk.Image();
	    int oldwidth = imagedat.get_pixbuf().get_width();
	    int oldheight = imagedat.get_pixbuf().get_height();
	    int width = this.scroll_view.get_allocated_width();
	    int height = this.scroll_view.get_allocated_height();
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
    
    public Gtk.Image getImage(){
	    Gtk.Image image = new Gtk.Image();
	    bool worked = false;
	    try{
		    Gdk.Pixbuf buf = new Gdk.Pixbuf.from_file(App.to_display[image_id].get_path());
		    image.set_from_pixbuf(buf);
		    worked = true;
	    }catch(GLib.Error e){
		    stderr.printf(e.message);
		    worked = false;
		    
	    }
	    return image;
    }
}
}
