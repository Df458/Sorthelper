using GLib;
using Gee;
namespace SortHelper
{

public struct Motion
{
    ArrayList<File> new_position;
    ArrayList<string> old_folder;
}

public class UndoList
{
    protected ArrayList<Motion?> past;
    protected ArrayList<Motion?> future;
    public int previous_count { get { return past.size; } }
    public int next_count { get { return future.size; } }
    public bool empty { get { return previous_count + next_count <= 0; } }

    public UndoList()
    {
        past = new ArrayList<Motion?>();
        future = new ArrayList<Motion?>();
    }

    public void clear()
    {
        past.clear();
        future.clear();
    }

    public bool undo()
    {
        if(past.size == 0)
            return false;

        Motion to_undo = past[past.size - 1];
        past.remove_at(past.size - 1);
        to_undo = move(to_undo);
        future.add(to_undo);
        App.item_list.add_list(to_undo.new_position);
        App.to_display = to_undo.new_position;
        App.main_window.display_files();

        return true;
    }

    public bool redo()
    {
        if(future.size == 0)
            return false;

        Motion to_redo = future[future.size - 1];
        future.remove_at(future.size - 1);
        App.item_list.remove_list(to_redo.new_position);
        to_redo = move(to_redo);
        past.add(to_redo);
        if(future.size == 0) {
            App.main_window.loadFile();
        } else {
            App.to_display = future[future.size - 1].new_position;
            App.main_window.display_files();
        }

        return true;
    }

    public void update(Motion moved)
    {
        past.add(moved);
        future.clear();
    }

    private Motion move(Motion to_move)
    {
        for(int i = 0; i < to_move.new_position.size; ++i) {
            try{
                string source = to_move.new_position[i].get_parent().get_path();
                string name = to_move.new_position[i].query_info ("standard::*", 0).get_name();
                File dest = File.new_for_path(to_move.old_folder[i] + "/" + name);
                to_move.new_position[i].move(dest, FileCopyFlags.OVERWRITE);
                to_move.new_position[i] = dest;
                to_move.old_folder[i] = source;
            }catch(Error e){
                stderr.printf("IO Error: %s\n", e.message);
            }
        }

        return to_move;
    }
}
}
