using GLib;
using Gee;
namespace SortHelper{
	public class ItemList{
		protected ArrayList<File> files;
		private GLib.Rand random;
		
		public ItemList.from_folder(File infile) {
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
		}
		
		public ArrayList<File> getFilesByCount(int count = 1, bool randomize = true){
			ArrayList<File> output_list = new ArrayList<File>();
			for(int i = 0; i < count; ++i)
				output_list.add(files[randomize ? random.int_range(0, files.size - 1) : i]);
			return output_list;
		}
		
		public ArrayList<File> getFilesByExpansion(File to_expand) {
			ArrayList<File> output_list = new ArrayList<File>();
			output_list.add(to_expand);
			string title = to_expand.get_basename();
			title = title.split(".")[0];
			//stdout.printf("Splicing...\n");
			while(title.length > 0 && title[title.length - 1] >= '0' && title[title.length - 1] <= '9') {
				title = title.splice(title.length - 2, title.length);
			}
			//stdout.printf("Searching...\n");
			if(title.length > 0) {
				foreach(File f in files) {
					if(f.get_basename().has_prefix(title) && f.get_basename() != to_expand.get_basename()) {
						//stdout.printf("Found " + f.get_basename() + "\n");
						output_list.add(f);
					}
				}
			}
			
			output_list.sort(alphasort);
			
			return output_list;
		}
		
		public int alphasort(File a, File b) {
			if(a.get_basename() < b.get_basename())
				return -1;
			else if(a.get_basename() == b.get_basename())
				return 0;
			return 1;
		}
		
		public void remove(File infile) {
			if(infile != null)
				files.remove(infile);
		}
	}
}
