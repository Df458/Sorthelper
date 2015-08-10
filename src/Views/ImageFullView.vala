using GLib;
using Gee;
namespace SortHelper
{
    public class ImageFullView : View, Gtk.VBox
    {
        //private Gtk.Toolbar toolbar;
        private Gtk.ScrolledWindow scroll_view;
        public int image_id = 0;
        private Gtk.Image dispimage;
        private Gtk.Image datimage;
        //private Gtk.ToolButton next_button;
        //private Gtk.ToolButton back_button;
        //private Gtk.SeparatorToolItem separator;

        public ImageFullView()
        {
            this.set_homogeneous(false);
            scroll_view = new Gtk.ScrolledWindow(null, null);
            dispimage = new Gtk.Image();
            scroll_view.add_with_viewport(dispimage);
            //separator = new Gtk.SeparatorToolItem();
            //separator.set_expand(true);
            //next_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-next", Gtk.IconSize.SMALL_TOOLBAR), "Next");
            //next_button.clicked.connect(() => {
                //if(image_id < App.to_display.size - 1) {
                    //image_id++;
                    //loadImage();
                //}
            //});
            //back_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-previous", Gtk.IconSize.SMALL_TOOLBAR), "Previous");
            //back_button.clicked.connect(() => {
                //if(image_id > 0) {
                    //image_id--;
                    //loadImage();
                //}
            //});
            //toolbar = new Gtk.Toolbar();
            //toolbar.insert(back_button, 0);
            //toolbar.insert(separator, 1);
            //toolbar.insert(next_button, 2);
            this.pack_start(scroll_view, true, true, 0);
            //this.pack_start(toolbar, false, false, 1);
        }

        //public void resetPage() {
            //image_id = 0;
            //loadImage();
        //}

        public void resize()
        {
            if(datimage.get_pixbuf() != null) {
                dispimage.set_from_pixbuf(resizeImage(datimage).get_pixbuf());
            } else if(datimage.get_animation() != null) {
                dispimage.set_from_animation(datimage.get_animation());
            }
        }

        public bool load(File infile)
        {
            image_id = 0;
            datimage = new Gtk.Image();
            try{
                Gdk.PixbufAnimation buf = new Gdk.PixbufAnimation.from_file(infile.get_path());
                if(buf == null)
                    stderr.printf("ERROR: Animation is null!\n");
                if(buf.is_static_image())
                    datimage.set_from_pixbuf(buf.get_static_image());
                else {
                    datimage.set_from_animation(buf);
                }
            }catch(GLib.Error e){
                stderr.printf("Failed to load image: %s\n", e.message);
            }
            resize();
            return true;
        }

        public void display()
        {
            resize();
        }

        public void unload() {}

        // TODO: Remove this, replace in mainwindow
        public void fileRemoved()
        {
            //if(image_id >= App.to_display.size) {
                //image_id = App.to_display.size - 1;
            //}
            //loadImage();
        }

        public Gtk.Image resizeImage(Gtk.Image imagedat)
        {
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
    }
}
