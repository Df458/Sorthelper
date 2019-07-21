namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/VideoView.ui")]
    public class VideoView : View, Gtk.Box
    {
        [GtkChild]
        Gtk.DrawingArea video_area;
        Gst.Element src;
        bool prepared = false;
        uint *handle;
        private int video_id = 0;

        public VideoView()
        {
            src = Gst.ElementFactory.make("playbin", "player");
        }

        public void display()
        {
            src.bus.add_watch(0,(bus,message) => {
                if(Gst.Video.is_video_overlay_prepare_window_handle_message (message)) {
                    Gst.Video.Overlay overlay = message.src as Gst.Video.Overlay;
                    assert (overlay != null);

                    overlay.set_window_handle (handle);
                    prepared = true;
                }
                return true;
            });
        
            src.set_state(Gst.State.PLAYING);
        }

	    public bool load(File infile)
        {
            video_id = 0;
            src = Gst.ElementFactory.make("playbin", "player");
            src["uri"] = "file://" + infile.get_path();
            return true;
        }	

        public void resize() {}

        public void unload()
        {
            src.set_state(Gst.State.NULL);
        }

        [GtkCallback]
        private void play_toggled()
        {
            Gst.State state;
            src.get_state(out state, null, Gst.CLOCK_TIME_NONE);
            if(state == Gst.State.READY || state == Gst.State.PAUSED)
                src.set_state(Gst.State.PLAYING);
            else
                src.set_state(Gst.State.PAUSED);
        }

        [GtkCallback]
        private void volume_changed()
        {
            // TODO
        }

        [GtkCallback]
        private void prepare_xid()
        {
            handle = (uint*)((Gdk.X11.Window)video_area.get_window()).get_xid();
        }
    }
}
