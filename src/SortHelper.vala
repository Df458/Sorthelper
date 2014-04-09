using Gtk;
using Gdk;
using GLib;
using Gee;
namespace SortHelper{
public class App : Granite.Application{
	
	private static App _instance;
    public static App instance {
        get {
            if (_instance == null)
                _instance = new App ();
            return _instance;
        }
    }
	
	public static MainWindow main_window;
	public static Unity.LauncherEntry entry;
	public static ArrayList<string> files;
	
	construct{
		program_name = "SortHelper";
		exec_name = "sorthelper";
		app_years = "2014";
		//app_icon = "singularity-icon";
		//app_launcher = "SortHelper.desktop";
		build_version = "0.0.1";
		application_id = "org.sorthelper";
		about_authors = {"Hugues Ross <hugues.ross@gmail.com>", null};
		about_artists = {"Hugues Ross <hugues.ross@gmail.com>", null};
		about_comments = "Simple file sorting helper app";
		about_license_type = License.GPL_3_0;
		_instance = this;
	}
	protected override void activate(){
		if (main_window == null){
			
		main_window = new MainWindow();
		main_window.build_all();
		main_window.set_application(this);
		entry = Unity.LauncherEntry.get_for_desktop_id ("SortHelper.desktop");
		main_window.getImage();
		main_window.present();
		}
		
	}
}
}