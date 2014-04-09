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
	}
	
	public void activated(){
	try{
		File f = File.new_for_path (App.main_window.current_image_location);
		App.main_window.list.remove(App.main_window.current_image_location);
		App.main_window.getImage();
		string name = f.query_info ("standard::*", 0).get_name();
		File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
		f.move(f2, FileCopyFlags.ALL_METADATA);
		} catch (Error e) {
				stderr.printf ("Error: %s\n", e.message);
				return;
		}
	}
	
	public Granite.Widgets.SourceList.ExpandableItem UIElement;
	public File owned_directory;
	public ArrayList<DirItem> children;
}
}
