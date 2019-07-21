using Gtk;
using Gdk;
using GLib;
using Gee;
namespace SortHelper
{
public class App : Gtk.Application
{
    
    private static App _instance;
    public static App instance
    {
	get {
	    if (_instance == null)
		_instance = new App ();
	    return _instance;
	}
    }
    
    public static MainWindow main_window;
    public static ArrayList<File> to_display;
    public static ItemList item_list;
    public static UndoList undo_list;
    public bool batch_mode { get; set; default = true; }
    public static bool auto_reload = false;
    public static string last_dest = "";
    public static GLib.Settings app_settings;
    
    construct
    {
        /* program_name = "SortHelper"; */
        /* exec_name = "sorthelper"; */
        /* app_years = "2014"; */
        /* //app_icon = "singularity-icon"; */
        /* //app_launcher = "SortHelper.desktop"; */
        /* build_version = "0.0.1"; */
        /* application_id = "org.sorthelper"; */
        /* about_authors = {"Hugues Ross <hugues.ross@gmail.com>", null}; */
        /* about_artists = {"Hugues Ross <hugues.ross@gmail.com>", null}; */
        /* about_comments = "Simple file sorting helper app"; */
        /* about_license_type = License.GPL_3_0; */
        _instance = this;
    }
    
    protected override void activate()
    {
        if (main_window == null) {
            app_settings = new GLib.Settings("org.df458.sorthelper");
            string? last_folder = null;
            if(app_settings.get_boolean("open-last")) {
                last_folder = app_settings.get_string("last-folder");
                auto_reload = true;
            }
            item_list = new ItemList();
            undo_list = new UndoList();

            add_action (new PropertyAction ("batch", this, "batch_mode"));

            set_accels_for_action("win.skip", { "<ctrl>s" });
            set_accels_for_action("app.batch", { "<ctrl>b" });

            main_window = new MainWindow();
            main_window.set_application(this);
            if(last_folder != null && last_folder.length > 0) {
                var directory = File.new_for_path (last_folder);
                item_list.load_folder(directory);
                main_window.loadFile();
            }
        }
    }

    // Returned if succeeded
    public static bool move_file(string location, File file)
    {
        Motion move = Motion();
        Motion failure_list = Motion();
        move.new_position = new ArrayList<File>();
        move.old_folder = new ArrayList<string>();
        failure_list.new_position = new ArrayList<File>();
        failure_list.old_folder = new ArrayList<string>();
        try{
            string source = file.get_parent().get_path();
            string name = file.query_info ("standard::*", 0).get_name();
            File f2 = File.new_for_uri(location + "/" + name);
            file.move(f2, FileCopyFlags.ALL_METADATA);
            move.new_position.add(f2);
            move.old_folder.add(location);
            move.new_position.add(file);
            move.old_folder.add(source);
            item_list.remove(file);
            to_display.remove(file);
        } catch (Error e) {
            stderr.printf ("IO Error: %s\n", e.message);
            last_dest = location;
            return false;
        }
        undo_list.update(move);
        return true;
    }

    // Returns a list of failures
    public static Motion move_files(string location, ArrayList<File> files)
    {
        Motion move = Motion();
        Motion failure_list = Motion();
        move.new_position = new ArrayList<File>();
        move.old_folder = new ArrayList<string>();
        failure_list.new_position = new ArrayList<File>();
        failure_list.old_folder = new ArrayList<string>();
        for(int i = 0; i < files.size; ++i) {	
            string name = "";
            try{
                File f = files[i];
                string source = f.get_parent().get_path();
                name = f.query_info ("standard::*", 0).get_name();
                File f2 = File.new_for_uri(location + "/" + name);
                stderr.printf("From: %s\n", location + "/" + name);
                failure_list.new_position.add(f);
                failure_list.old_folder.add("");
                f.move(f2, FileCopyFlags.ALL_METADATA);
                move.new_position.add(f2);
                move.old_folder.add(source);
            } catch (Error e) {
                stderr.printf ("IO Error: %s\n", e.message);
                //App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
                //App.main_window.container1.show_all();
                last_dest = location;
                failure_list.old_folder[failure_list.old_folder.size - 1] = location + "/" + name;
                continue;
            }
            item_list.remove(App.to_display[i]);
            to_display.remove_at(i);
            --i;
        }
        if(move.new_position.size > 0)
            undo_list.update(move);
        return failure_list;
    }

    public static void save_last()
    {
        app_settings.set_string("last-folder", item_list.origin_folder.get_path());
    }
}
}
