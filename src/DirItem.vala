using GLib;
using Gee;
namespace SortHelper {
public class DirItem : Granite.Widgets.SourceList.ExpandableItem {
    public File owned_directory;
    public bool unfiltered_expand;

    public DirItem(){
    }
    
    public DirItem.FromFile(File infile){
        base(infile.get_basename());
        owned_directory = infile;
        ArrayList<File> list = new ArrayList<File>();
        //children = new ArrayList<DirItem>();
        FileInfo info;
        try{
            info = owned_directory.query_info ("standard::*", 0);
            //base(info.get_name());
            FileEnumerator enumerator = owned_directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                if(file_info.get_file_type () == FileType.DIRECTORY){
                    list.add(owned_directory.resolve_relative_path (file_info.get_name ()));
                }
            }
            foreach(File f in list)
                add(new DirItem.FromFile(f));
            //UIElement = new Granite.Widgets.SourceList.ExpandableItem(info.get_name());
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return;
        }
        activated.connect(activatedCallback);
        toggled.connect(() => {
            if(!App.main_window.filtering && !App.main_window.filterreset) { 
                unfiltered_expand = expanded;
            } else if(App.main_window.filterreset) {
                expanded = unfiltered_expand;
            } else
                expanded = true;
        });
        //UIElement.compare = compareItems;
    }

    public void addChild(DirItem child) {
        //children.add(child);
        //UIElement.add(child.UIElement);
    }
    
    public void activatedCallback(){
        if(App.batch_mode) {
            for(int i = 0; i < App.to_display.size; ++i) {	
                string name;
                File f = File.new_for_path (App.to_display[i].get_path());
                name = f.query_info ("standard::*", 0).get_name();
                try{
                    File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
                    f.move(f2, FileCopyFlags.ALL_METADATA);
                } catch (Error e) {
                    stderr.printf ("IO Error: %s\n", e.message);
                    App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
                    App.main_window.container1.show_all();
                    App.last_dest = owned_directory.get_path();
                    continue;
                }
                App.item_list.remove(App.to_display[i]);
                App.to_display.remove_at(i);
                --i;
            }
        } else {
            int sel = App.main_window.fullview.image_id;
            File f = File.new_for_path (App.to_display[sel].get_path());
            string name = f.query_info ("standard::*", 0).get_name();
            try{
                File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
                f.move(f2, FileCopyFlags.ALL_METADATA);
                if(App.main_window.fullview.image_id >= App.to_display.size)
                    App.main_window.fullview.image_id--;
            } catch (Error e) {
                stderr.printf ("IO Error: %s\n", e.message);
                App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
                App.main_window.container1.show_all();
                App.last_dest = owned_directory.get_path();
                return;
            }
            App.item_list.remove(App.to_display[sel]);
            App.to_display.remove_at(sel);
        }
        if(App.to_display.size == 0) {
            App.main_window.loadFile();
        } else {
            App.main_window.resetView();
        }
    }

    public override int compare(Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b){
        if(a.name > b.name)
        return 1;
        else if(b.name > a.name)
        return -1;
        return 0;
    }

    public void displayChildren() {
        visible = true;
        foreach(Granite.Widgets.SourceList.Item child in children)
            ((DirItem)child).displayChildren();
    }

    public bool has(string str) {
        if(name.down().contains(str.down()) || parent.name.down().contains(str.down()))
            return true;
        foreach(Granite.Widgets.SourceList.Item child in children)
            if(((DirItem)child).has(str))
                return true;
        return false;
        //visible = false;
        //if(name.contains(str)) {
            //displayChildren();
            //return true;
        //}

        //foreach(Granite.Widgets.SourceList.Item child in children) {
            //if(((DirItem)child).has(str)) {
                //visible = true;
            //}
        //}

        //return visible;
    }
}

}
