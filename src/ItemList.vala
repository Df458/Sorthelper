using GLib;
using Gee;
namespace SortHelper{
public class ItemList{
    protected ArrayList<File> files;
    private GLib.Rand random;
    public File origin_folder;
    public int orig_size = 0;
    public int size { get {return files.size;} }
    
    public ItemList.from_folder(File infile) {
        origin_folder = infile;
        random = new GLib.Rand();
        try {
            files = new ArrayList<File>();
            
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
    }
    
    public bool is_empty() {
	return files.size <= 0;
    }
    
    public ArrayList<File> getFilesByCount(int count = 1, bool randomize = true){
        ArrayList<File> output_list = new ArrayList<File>();
        for(int i = 0; i < count; ++i)
            output_list.add(files[randomize ? random.int_range(0, files.size) : i]);
        return output_list;
    }
    
    public async ArrayList<File> getFilesByExpansion(File to_expand) {
	ArrayList<File> output_list = new ArrayList<File>();
    
	output_list.add(to_expand);
	string title = to_expand.get_basename();
	stdout.printf("Expanding %s...", title);
	stdout.flush();
	string[] tnum = extractnumber(title);

	if(tnum.length == 3 && (tnum[0] != "" || !tnum[2].has_prefix("."))) {
	    for(int i = files.index_of(to_expand) + 1; i < files.size; ++i) {
		File f = files[i];
		string[] fnum = extractnumber(f.get_basename());
		if(fnum[0] == tnum[0] && fnum[2] == tnum[2]) {
		    stdout.printf("Found " + f.get_basename() + "\n");
		    output_list.add(f);
		} else {
		    stdout.printf("Stop at " + f.get_basename() + "\n");
		    break;
		}
	    }
	    for(int i = files.index_of(to_expand) - 1; i >= 0; --i) {
		File f = files[i];
		string[] fnum = extractnumber(f.get_basename());
		if(fnum[0] == tnum[0] && fnum[2] == tnum[2]) {
		    stdout.printf("Found " + f.get_basename() + "\n");
		    output_list.add(f);
		} else {
		    stdout.printf("Stop at " + f.get_basename() + "\n");
		    break;
		}
	    }
	}
	output_list.sort(alphasort);

	return output_list;
    }

    private string[] extractnumber(string input) {
        for(int i = input.length - 1; i >= 0; --i) {
            if(input[i] >= '0' && input[i] <= '9') {
                int j;
                for(j = i; j >= 0 && input[j] >= '0' && input[j] <= '9'; --j);
                    return {input.slice(0, j + 1), input.slice(j + 1, i + 1), input.slice(i + 1, input.length)};
            }
        }
        return {input};
    }
    
    public int alphasort(File a, File b) {
        //if(a.get_basename() < b.get_basename())
            //return -1;
        //else if(a.get_basename() == b.get_basename())
            //return 0;
        //return 1;
        if(a.get_basename() == b.get_basename())
            return 0;
        string[] s1 = extractnumber(a.get_basename());
        string[] s2 = extractnumber(b.get_basename());
        if(s1[0] == s2[0]) {
            int i1 = int.parse(s1[1]);
            int i2 = int.parse(s2[1]);
            if(i1 == i2) {
                if(s1[2] < s2[2])
                    return -1;
                return 1;
            } else if(i1 < i2)
                return -1;
            return 1;
        } else if(s1[0] < s2[0])
            return -1;
        return 1;
    }
    
    public void remove(File infile) {
	if(infile != null)
	    files.remove(infile);
    }
}
}
