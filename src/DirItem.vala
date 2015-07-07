using GLib;
using Gee;
namespace SortHelper
{
public class DirItem : Granite.Widgets.SourceList.ExpandableItem
{
    public File owned_directory;
    public bool unfiltered_expand;

    public DirItem()
    {
    }
    
    public DirItem.FromFile(File infile)
    {
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

    public void addChild(DirItem child)
    {
    }
    
    public void activatedCallback()
    {
        Motion move = new Motion();
        Motion failure_list = new Motion();
        move.new_position = new ArrayList<File>();
        move.old_folder = new ArrayList<string>();
        failure_list.new_position = new ArrayList<File>();
        failure_list.old_folder = new ArrayList<string>();
        if(App.batch_mode) {
            for(int i = 0; i < App.to_display.size; ++i) {	
                string name;
                File f = File.new_for_path (App.to_display[i].get_path());
                string source = f.get_parent().get_path();
                name = f.query_info ("standard::*", 0).get_name();
                File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
                failure_list.new_position.add(f);
                failure_list.old_folder.add("");
                try{
                    f.move(f2, FileCopyFlags.ALL_METADATA);
                    move.new_position.add(f2);
                    move.old_folder.add(source);
                } catch (Error e) {
                    stderr.printf ("IO Error: %s\n", e.message);
                    App.main_window.container1.pack_end(App.main_window.errorbar, false, false);
                    App.main_window.container1.show_all();
                    App.last_dest = owned_directory.get_path();
                    failure_list.old_folder[failure_list.old_folder.size - 1] = owned_directory.get_path() + "/" + name;
                    continue;
                }
                App.item_list.remove(App.to_display[i]);
                App.to_display.remove_at(i);
                --i;
            }
            if(failure_list.new_position.size > 0)
                App.main_window.move_failed(failure_list);
            if(move.new_position.size > 0)
                App.undo_list.update(move);
        } else {
            int sel = App.main_window.fullview.image_id;
            File f = File.new_for_path (App.to_display[sel].get_path());
            string source = f.get_parent().get_path();
            string name = f.query_info ("standard::*", 0).get_name();
            File f2 = File.new_for_path(owned_directory.get_path() + "/" + name);
            try{
                f.move(f2, FileCopyFlags.ALL_METADATA);
                if(App.main_window.fullview.image_id >= App.to_display.size)
                    App.main_window.fullview.image_id--;
                move.new_position.add(f2);
                move.old_folder.add(owned_directory.get_path());
            } catch (Error e) {
                stderr.printf ("IO Error: %s\n", e.message);
                App.main_window.move_failed_single(owned_directory.get_path() + "/" + name);
                App.last_dest = owned_directory.get_path();
                return;
            }
            move.new_position.add(f);
            move.old_folder.add(source);
            App.undo_list.update(move);
            App.item_list.remove(App.to_display[sel]);
            App.to_display.remove_at(sel);
        }
        if(App.to_display.size == 0) {
            App.main_window.loadFile();
        } else {
            App.main_window.resetView();
        }
    }

    public override int compare(Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b)
    {
        if(a.name > b.name)
        return 1;
        else if(b.name > a.name)
        return -1;
        return 0;
    }

    public void displayChildren()
    {
        visible = true;
        foreach(Granite.Widgets.SourceList.Item child in children)
            ((DirItem)child).displayChildren();
    }

    public bool has(string str)
    {
        if(name.down().contains(str.down()) || parent.name.down().contains(str.down()))
            return true;
        foreach(Granite.Widgets.SourceList.Item child in children)
            if(((DirItem)child).has(str))
                return true
                    ;
        return false;
    }

    public override Gtk.Menu? get_context_menu()
    {
        stderr.printf("STUFF\n");
        Menu model = new Menu();
        model.append("Cool Stuff", null);
        Gtk.Menu menu = new Gtk.Menu.from_model(model);
        return menu;
    }
}

public class BaseItem : Granite.Widgets.SourceList.ExpandableItem
{
    public BaseItem(string name)
    {
        base(name);
    }

    public override int compare(Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b)
    {
        if(a.name > b.name)
        return 1;
        else if(b.name > a.name)
        return -1;
        return 0;
    }

    public bool has(string str)
    {
        if(name.down().contains(str.down()) || parent.name.down().contains(str.down()))
            return true;
        foreach(Granite.Widgets.SourceList.Item child in children)
            if(((DirItem)child).has(str))
                return true
                    ;
        return false;
    }
}
}
