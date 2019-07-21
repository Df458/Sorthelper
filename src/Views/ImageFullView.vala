using GLib;
using Gee;
namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/ImageFullView.ui")]
    public class ImageFullView : View, Gtk.ScrolledWindow
    {
        public int image_id = 0;
        [GtkChild]
        private Gtk.Image dispimage;
        private Gtk.Image datimage;

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

        public Gtk.Image resizeImage(Gtk.Image imagedat)
        {
            Gtk.Image image = new Gtk.Image();
            int oldwidth = imagedat.get_pixbuf().get_width();
            int oldheight = imagedat.get_pixbuf().get_height();
            int width = this.get_allocated_width();
            int height = this.get_allocated_height();
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
