using GLib;
using Gee;
namespace SortHelper{
    public class WebView : View, Gtk.VBox{
        private Gtk.Toolbar toolbar;
        //private Gtk.ScrolledWindow scroll_view;
        public int item_id = 0;
        private Gtk.ToolButton next_button;
        private Gtk.ToolButton back_button;
        private Gtk.SeparatorToolItem separator;
        private Gtk.Label count_label;
        private Gtk.SeparatorToolItem separator_r;
        private WebKit.WebView web_view;
        public bool is_swf = false;

        public WebView() {
            this.set_homogeneous(false);
            //scroll_view = new Gtk.ScrolledWindow(null, null);
            //scroll_view.add_with_viewport(dispimage);
            separator = new Gtk.SeparatorToolItem();
            separator.set_expand(true);
            separator_r = new Gtk.SeparatorToolItem();
            separator_r.set_expand(true);
            next_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-next", Gtk.IconSize.SMALL_TOOLBAR), "Next");
            next_button.clicked.connect(() => {
                if(item_id < App.to_display.size - 1) {
                    item_id++;
                    loadItem();
                }
            });
            back_button = new Gtk.ToolButton(new Gtk.Image.from_icon_name("go-previous", Gtk.IconSize.SMALL_TOOLBAR), "Previous");
            back_button.clicked.connect(() => {
                if(item_id > 0) {
                    item_id--;
                    loadItem();
                }
            });
            toolbar = new Gtk.Toolbar();
            toolbar.insert(back_button, 0);
            toolbar.insert(separator, 1);
            Gtk.ToolItem item = new Gtk.ToolItem();
            count_label = new Gtk.Label("Image");
            item.add(count_label);
            toolbar.insert(item, 2);
            toolbar.insert(separator_r, 3);
            toolbar.insert(next_button, 4);

            web_view = new WebKit.WebView();
            WebKit.Settings view_settings = new WebKit.Settings();
            view_settings.enable_javascript = true;
            view_settings.enable_developer_extras = true;
            //view_settings.enable_file_access_from_file_uris = true;
            web_view.context_menu.connect(()=>{return false;});
            web_view.set_settings(view_settings);
            web_view.get_context().get_security_manager().register_uri_scheme_as_cors_enabled("file");
            web_view.decide_policy.connect((decision, type) => {
                if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
                    WebKit.NavigationPolicyDecision nav_dec = (WebKit.NavigationPolicyDecision) decision;
                    if(nav_dec.get_navigation_action().get_navigation_type() != WebKit.NavigationType.LINK_CLICKED)
                        return false;
                    try {
                        GLib.Process.spawn_command_line_async("xdg-open " + nav_dec.get_navigation_action().get_request().uri);
                        nav_dec.ignore();
                    } catch(Error e) {
                        stderr.printf(e.message);
                    }
                    return true;
                }
                return false;
            });

            //this.pack_start(scroll_view, true, true, 0);
            this.pack_start(web_view, true, true, 0);
            this.pack_start(toolbar, false, false, 1);
        }

        public void loadItem() {
            next_button.set_sensitive(item_id < App.to_display.size - 1);
            back_button.set_sensitive(item_id > 0);
            count_label.label = App.to_display[item_id].get_basename();
            if(!is_swf)
                web_view.load_uri(App.to_display[item_id].get_uri());
            else {
                load_swf(App.to_display[item_id]);
            }
            if(App.to_display.size > 1) {
                count_label.label += " (" + (item_id+1).to_string() + "/" + App.to_display.size.to_string() + ")";
            }
        }

        public void load_swf(File swf_file) {
            try {
            //DataInputStream ds = new DataInputStream(swf_file.read());
            //ds.seek(0, SeekType.END);
            //var size = ds.tell();
            //ds.seek(0, SeekType.SET);
            //uint8[] buffer = new uint8[size];
            //ds.read(buffer);
            //web_view.load_html("<html>\n<body>\n<object width=\"100%\" height=\"100%\" data=\"data:application/x-shockwave-flash;base64," + Base64.encode(buffer) +  "\"/>\n</body>\n</html>", null);
                web_view.load_html("<html>\n<body>\n<embed width=\"100%\" height=\"100%\" src=\"" + swf_file.get_uri() + "\"/>\n</body>\n</html>", App.item_list.origin_folder.get_uri());
            } catch(Error e) {
                stderr.printf("Error displaying swf file: %s\n", e.message);
            }
        }

        public bool load() {
            item_id = 0;
            loadItem();
            return true;
        }

        public void display() {
        }

        public void unload() {}

        public void fileRemoved() {
            if(item_id >= App.to_display.size) {
                item_id = App.to_display.size - 1;
            }
            load();
        }
    }
}

