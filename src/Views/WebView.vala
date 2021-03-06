using GLib;
using Gee;
namespace SortHelper
{
    [GtkTemplate (ui = "/org/df458/sorthelper/WebView.ui")]
    public class WebView : View, Gtk.Box
    {
        public int item_id = 0;
        private WebKit.WebView web_view;
        public bool is_swf = false;

        public WebView()
        {
            web_view = new WebKit.WebView();
            WebKit.Settings view_settings = new WebKit.Settings();
            view_settings.enable_javascript = true;
            view_settings.enable_developer_extras = true;
            //web_view.context_menu.connect(()=>{return false;});
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

            this.pack_start(web_view, true, true, 0);
        }

        public void load_swf(File swf_file)
        {
            web_view.load_html("<html><body><embed width=\"100%\" height=\"100%\" src=\"" + swf_file.get_uri() + "\"/></body></html>", swf_file.get_parent().get_uri());
        }

        public bool load(File infile)
        {
            item_id = 0;
            if(!is_swf)
                web_view.load_uri(infile.get_uri());
            else {
                load_swf(infile);
            }
            return true;
        }

        public void display()
        {
        }

        public void resize() {  }

        public void unload()
        {
            web_view.load_html("<html></html>", null);
        }
    }
}

