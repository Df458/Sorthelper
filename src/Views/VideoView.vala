namespace SortHelper
{
    public class VideoView : View, Gtk.Box
    {
        Gtk.Toolbar toolbar;
        Gtk.ToolButton play_pause_button;
        Gtk.DrawingArea area;
        Gst.Element src;
        bool prepared = false;
        uint *handle;
        private int video_id = 0;

        public VideoView()
        {
            this.orientation = Gtk.Orientation.VERTICAL;
            src = Gst.ElementFactory.make("playbin", "player");

            area = new Gtk.DrawingArea();
            area.realize.connect(() => {
                handle = (uint*)((Gdk.X11.Window)area.get_window()).get_xid();
            });

            toolbar = new Gtk.Toolbar();
            play_pause_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("media-playback-start", Gtk.IconSize.SMALL_TOOLBAR), "Play/Pause");
            play_pause_button.clicked.connect(() => {
                Gst.State state;
                src.get_state(out state, null, Gst.CLOCK_TIME_NONE);
                if(state == Gst.State.READY || state == Gst.State.PAUSED)
                    src.set_state(Gst.State.PLAYING);
                else
                    src.set_state(Gst.State.PAUSED);
            });
            toolbar.insert(play_pause_button, 0);

            this.pack_start(area, true, true);
            this.pack_end(toolbar, false, false);
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

        public void unload()
        {
            src.set_state(Gst.State.NULL);
        }
    }
}