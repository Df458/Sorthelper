appsrc = [
    'main.vala',
    'Init.vala',

    'AddFolderPopover.vala',
    'ItemList.vala',
    'MainWindow.vala',
    'SettingsPane.vala',
    'SortHelper.vala',
    'UndoList.vala',

    'Views/ArchiveView.vala',
    'Views/AudioView.vala',
    'Views/ComicView.vala',
    'Views/DefaultView.vala',
    'Views/EmptyView.vala',
    'Views/ImageFullView.vala',
    'Views/ImageSetView.vala',
    'Views/VideoView.vala',
    'Views/View.vala',
    'Views/WebView.vala',
    'Views/WelcomeView.vala',
]
app_glade_target = shared_library('sorthelper', appsrc + resources,
                        dependencies : deps,
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path])
apptarget = executable('sorthelper', appsrc + resources,
                        dependencies : deps,
                        vala_args : ['--target-glib=2.38', '--gresources=../' + resource_path],
                        install : true)
