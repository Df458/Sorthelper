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
		
		public ImageFullView() {
			this.set_homogeneous(false);
			scroll_view = new Gtk.ScrolledWindow(null, null);
			dispimage = new Gtk.Image();
			scroll_view.add_with_viewport(dispimage);
			separator = new Gtk.SeparatorToolItem();
			separator.set_expand(true);
			next_button = new Gtk.ToolButton.from_stock(Gtk.Stock.GO_FORWARD);
			next_button.clicked.connect(nbut);
			back_button = new Gtk.ToolButton.from_stock(Gtk.Stock.GO_BACK);
			back_button.clicked.connect(bbut);
			toolbar = new Gtk.Toolbar();
			toolbar.insert(back_button, 0);
			toolbar.insert(separator, 1);
			toolbar.insert(next_button, 2);
			this.pack_start(toolbar, false, false, 0);
			this.pack_start(scroll_view, true, true, 1);
		}
		
		public void nbut() {
			if(image_id < App.to_display.size - 1) {
				image_id++;
				loadImage();
			}
		}
		
		public void bbut() {
			if(image_id > 0) {
				image_id--;
				loadImage();
			}
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
