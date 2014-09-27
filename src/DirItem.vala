using GLib;
using Gee;
namespace SortHelper{
public class DirItem{
	public DirItem(){
	}
	
	public DirItem.FromFile(File infile){
		owned_directory = infile;
		ArrayList<File> list = new ArrayList<File>();
		children = new ArrayList<DirItem>();
		FileInfo info;
		try{
				info = owned_directory.query_info ("standard::*", 0);
				FileEnumerator enumerator = owned_directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

				FileInfo file_info;
				while ((file_info = enumerator.next_file ()) != null) {
				    if(file_info.get_file_type () == FileType.DIRECTORY){
				    	list.add(owned_directory.resolve_relative_path (file_info.get_name ()));
				    }
				}
				if(children.size > 0){
				UIElement = new Granite.Widgets.SourceList.ExpandableItem(info.get_name());
			}else{
				UIElement = new Granite.Widgets.SourceList.ExpandableItem(info.get_name());
			}
			for(int i = 0; i < list.size; ++i){
				children.add(new DirItem.FromFile(list[i]));
				if(children[i].UIElement != null)
					UIElement.add(children[i].UIElement);
			}
			} catch (Error e) {
				stderr.printf ("Error: %s\n", e.message);
				return;
			}
			UIElement.activated.connect(activated);
			//UIElement.compare = compareItems;
	}
	
	public void activated(){
		if(App.batch_mode) {
			while(App.to_display.size > 0) {	
				try{
					File f = File.new_for_path (App.to_display[0].get_path());
					App.item_list.remove(App.to_display[0]);
					App.to_display.remove_at(0);
					string name = f.query_info ("standard::*", 0).get_name();
					File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
					f.move(f2, FileCopyFlags.ALL_METADATA);
				} catch (Error e) {
					stderr.printf ("IO Error: %s\n", e.message);
					App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
					App.main_window.container1.show_all();
					return;
				}
			}
		} else {
			int sel = App.main_window.fullview.image_id;
			try{
				File f = File.new_for_path (App.to_display[sel].get_path());
				App.item_list.remove(App.to_display[sel]);
				App.to_display.remove_at(sel);
				string name = f.query_info ("standard::*", 0).get_name();
				File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
				f.move(f2, FileCopyFlags.ALL_METADATA);
				App.main_window.fullview.image_id--;
			} catch (Error e) {
				stderr.printf ("IO Error: %s\n", e.message);
				App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
				App.main_window.container1.show_all();
				return;
			}
		}
		if(App.to_display.size == 0) {
			App.main_window.loadImage();
		} else {
			App.main_window.fullview.resetPage();
		}
		
	}
	
	public Granite.Widgets.SourceList.ExpandableItem UIElement;
	public File owned_directory;
	public ArrayList<DirItem> children;
}

public static int compareItems(Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b){
	if(a.name > b.name)
		return 1;
	else if(b.name > a.name)
		return -1;
	return 0;
}
}
