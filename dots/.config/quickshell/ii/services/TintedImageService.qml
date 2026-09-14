pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// Caches Material-You-tinted versions of remotely-fetched images (e.g. sports
// team badges) that can't be pre-baked into DynamicTheme like local app icons.
// Recoloring itself is done by scripts/colors/recolor_remote_image.py, which
// reuses the same gradient LUT as the local icon theme pipeline.
Singleton {
    id: root

    property var cache: ({})
    property var pending: ({})
    property int revision: 0

    // Returns the tinted local path if already cached, otherwise kicks off a
    // background fetch+recolor and returns the original url as a fallback
    // until revision bumps and the caller re-reads getTinted().
    function getTinted(url) {
        if (!url) return "";
        if (root.cache[url]) return root.cache[url];
        if (!root.pending[url]) {
            root.pending[url] = true;
            let proc = tintProcessComponent.createObject(root, { url: url });
            proc.running = true;
        }
        return url;
    }

    Component {
        id: tintProcessComponent
        Process {
            id: proc
            property string url: ""
            command: ["python3", Directories.scriptPath + "/colors/recolor_remote_image.py", url]

            stdout: StdioCollector {
                onStreamFinished: {
                    let result = text.trim();
                    if (result) {
                        root.cache[proc.url] = result;
                        root.revision += 1;
                    }
                    delete root.pending[proc.url];
                    proc.destroy();
                }
            }
        }
    }
}
