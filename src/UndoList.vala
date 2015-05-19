using GLib;
using Gee;
namespace SortHelper
{

public struct Motion
{
    File new_position;
    string old_folder;
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

    public bool undo()
    {
        // TODO: Take the last past value, and place the move in the future
        
        return true;
    }

    public bool redo()
    {
        // TODO: Take the last future value, and place the move in the past

        return true;
    }

    private Motion move(Motion to_move)
    {
        // TODO: Move the image to old_folder, then flip the values

        return to_move;
    }
}
}
