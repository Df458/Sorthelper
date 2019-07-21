namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/AudioView.ui")]
    public class AudioView : View, Gtk.Box
    {
        Gst.Element src;
        Gst.Element sink;
        private int audio_id = 0;

        // TODO: Update
        [GtkChild]
        private Gtk.ProgressBar play_progress;

        public AudioView()
        {
            src = Gst.ElementFactory.make("playbin2", "player");
            sink = Gst.ElementFactory.make("fakesink", "sf");
            src["video-sink"] = sink;
        }

        public void display()
        {
            src.set_state(Gst.State.READY);
        }

	    public bool load(File infile)
        {
            audio_id = 0;
            src["uri"] = "file://" + infile.get_path();
            src.set_state(Gst.State.READY);
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
    }
}

