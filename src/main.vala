public static int main (string[] args){
    Gst.init(ref args);
    Gtk.init(ref args);
    return SortHelper.App.instance.run(args);
}
