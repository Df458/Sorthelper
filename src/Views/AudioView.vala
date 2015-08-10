namespace SortHelper
{
    // TODO: VBox is deprecated
    public class AudioView : View, Gtk.VBox
    {
        Granite.Widgets.Welcome area;
        Gtk.Toolbar toolbar;
        Gtk.ToolButton play_pause_button;
        Gst.Element src;
        Gst.Element sink;
        private int audio_id = 0;

        public AudioView()
        {
            src = Gst.ElementFactory.make("playbin2", "player");
            sink = Gst.ElementFactory.make("fakesink", "sf");
            src["video-sink"] = sink;

            area = new Granite.Widgets.Welcome("Title", "Extra");
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
            src.set_state(Gst.State.READY);
        }

	    public bool load(File infile)
        {
            audio_id = 0;
            src["uri"] = "file://" + infile.get_path();
            area.title = infile.get_basename();
            src.set_state(Gst.State.READY);
            return true;
        }	

        public void unload()
        {
            src.set_state(Gst.State.READY);
        }

        public void fileRemoved()
        {
            //if(audio_id >= App.to_display.size) {
                //audio_id = App.to_display.size - 1;
            //}
            //load_audio();
        }
    }
}

