using GLib;
using Gee;
namespace SortHelper
{
	public class ComicView : View, Gtk.Box
    {
        Archive.Read archive;
        Archive.WriteDisk output;
        FileStream fs;
        private Gtk.ScrolledWindow scroll_view;
        private Gtk.Image dispimage;
        private Gtk.Image datimage;

        public ComicView()
        {
            this.orientation = Gtk.Orientation.VERTICAL;
            this.set_homogeneous(false);
            scroll_view = new Gtk.ScrolledWindow(null, null);
            dispimage = new Gtk.Image();
            scroll_view.add_with_viewport(dispimage);

            this.pack_start(scroll_view, true, true, 0);
        }

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
            archive = new Archive.Read();
            archive.support_filter_all();
            archive.support_format_all();
            output = new Archive.WriteDisk();
            output.set_standard_lookup();
            fs = FileStream.open(infile.get_path(), "r");
            Archive.Result res = archive.open_FILE(fs);
            if(res != Archive.Result.OK)
                return false;
            unowned Archive.Entry e;
            bool found_image = false;
            while(archive.next_header(out e) == Archive.Result.OK || !found_image) {
                if(e.pathname().has_suffix("png") || e.pathname().has_suffix("jpg") || e.pathname().has_suffix("jpeg")) {
                    found_image = true;
                    void* data;
                    size_t size;
                    Posix.off_t off;
                    e.set_pathname("/tmp/arc_img_tmp");
                    output.write_header(e);
                    while(true) {
                        Archive.Result r = archive.read_data_block(out data, out size, out off);
                        if(r == Archive.Result.EOF)
                            break;
                        output.write_data_block(data, size, off);
                    }
                    output.finish_entry();
                }
            }
            datimage = new Gtk.Image();
            try{
                Gdk.PixbufAnimation buf = new Gdk.PixbufAnimation.from_file("/tmp/arc_img_tmp");
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
        }

        public void unload()
        {
            archive.close();
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
