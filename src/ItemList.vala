using GLib;
using Gee;
namespace SortHelper
{
public class ItemList
{
    protected ArrayList<File> files;
    protected HashMap<File, int> indices;
    private GLib.Rand random;
    public File origin_folder;
    public int orig_size = 0;
    public int size { get {return files.size;} }
    
    public ItemList()
    {
        random = new GLib.Rand();
        files = new ArrayList<File>();
        indices = new HashMap<File, int>();
    }

    //public ItemList.from_folder(File infile)
    //{
        //origin_folder = infile;
        //random = new GLib.Rand();
        //files = new ArrayList<File>();
        //indices = new HashMap<File, int>();
        //try {
            //var enumerator = infile.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            //FileInfo file_info;
            //while ((file_info = enumerator.next_file ()) != null) {
                //files.add(enumerator.get_child(file_info));
            //}
        //}catch(GLib.Error e){
            //stderr.printf(e.message);
        //}
        //files.sort(alphasort);
        //orig_size = files.size;
    //}

    public void load_folder(File infile)
    {
        files.clear();
        indices.clear();
        origin_folder = infile;
        try {
            var enumerator = infile.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                files.add(enumerator.get_child(file_info));
            }
        }catch(GLib.Error e){
            stderr.printf(e.message);
        }
        files.sort(alphasort);
        orig_size = files.size;
        App.undo_list.clear();
    }
    
    public bool is_empty()
    {
        return files.size <= 0;
    }
    
    public ArrayList<File> getFilesByCount(int count = 1, bool randomize = true)
    {
        ArrayList<File> output_list = new ArrayList<File>();
        for(int i = 0; i < count; ++i)
            output_list.add(files[randomize ? random.int_range(0, files.size) : i]);
        return output_list;
    }
    
    public async ArrayList<File> getFilesByExpansion(File to_expand)
    {
        ArrayList<File> output_list = new ArrayList<File>();
        
        output_list.add(to_expand);
        string title = to_expand.get_basename();
        stdout.printf("Expanding %s...\n", title);
        stdout.flush();
        for(int i = files.index_of(to_expand) + 1; i < files.size; ++i) {
            File f = files[i];
            int res = in_set(title, f.get_basename(), to_expand);
            if(res != -1) {
                output_list.add(f);
                indices[f] = res;
                stdout.printf("Found " + f.get_basename() + "(%d)\n", res);
            } else {
                stdout.printf("Stop at " + f.get_basename() + "\n");
                break;
            }
        }
        for(int i = files.index_of(to_expand) - 1; i >= 0; --i) {
            File f = files[i];
            int res = in_set(title, f.get_basename(), to_expand);
            if(res != -1) {
                output_list.add(f);
                indices[f] = res;
                stdout.printf("Found " + f.get_basename() + " (%d)\n", res);
            } else {
                stdout.printf("Stop at " + f.get_basename() + "\n");
                break;
            }
        }
        output_list.sort(indexsort);
        indices.clear();
        stdout.flush();

        return output_list;
    }

    private int in_set(string file, string candidate, File orig)
    {
        bool difference_found = false;
        int ival = 0;
        int val = 0;

        int i = 0;
        int j = 0;
        while(i < file.length && j < candidate.length) {
            if(file[i] != candidate[j]) {
                if(difference_found || ((file[i] > '9' || file[i] < '0') && (candidate[j] > '9' || candidate[j] < '0')))
                    return -1;
                else {
                    difference_found = true;
                    while(i < file.length && file[i] <= '9' && file[i] >= '0') {
                        ival = ival * 10 + (file[i] - '0');
                        ++i;
                    }
                    while(j < candidate.length && candidate[j] <= '9' && candidate[j] >= '0') {
                        val = val * 10 + (candidate[j] - '0');
                        ++j;
                    }
                    continue;
                }
            }
            if(!difference_found) {
                if(candidate[i] <= '9' && candidate[i] >= '0')
                    ival = ival * 10 + (candidate[i] - '0');
                else
                    ival = 0;

                if(candidate[j] <= '9' && candidate[j] >= '0')
                    val = val * 10 + (candidate[j] - '0');
                else
                    val = 0;
            }
            ++i;
            ++j;
        }

        if(i != file.length || j != candidate.length || val >= 10000 || ival >= 10000)
            return -1;

        indices[orig] = ival;

        return val;
    }
    
    public int alphasort(File a, File b)
    {
        if(a.get_basename() == b.get_basename())
            return 0;
        if(a.get_basename() < b.get_basename())
            return -1;
        return 1;
    }
    
    public int indexsort(File a, File b)
    {
        if(indices[a] == indices[b])
            return 0;
        if(indices[a] < indices[b])
            return -1;
        return 1;
    }
    
    public void remove(File infile)
    {
        if(infile != null)
            files.remove(infile);
    }

    public void remove_list(ArrayList<File> infiles)
    {
        foreach(File f in infiles)
            if(f != null)
                foreach(File of in files)
                    if(f.get_uri() == of.get_uri())
                        files.remove(of);
    }

    public void add(File infile)
    {
        if(infile != null)
            files.add(infile);
    }

    public void add_list(ArrayList<File> infiles)
    {
        foreach(File f in infiles)
            if(f != null)
                files.add(f);
    }
}
}
