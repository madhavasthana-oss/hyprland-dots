// MediaBackend.qml --- playerctl metadata (art/title) + cava overlay
import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property string playerName: ""
    property string status: "Stopped"
    property string title: ""
    property string artist: ""
    property string album: ""
    property string artUrl: ""
    property bool cavaOn: Globals.cavaOverlay

    readonly property bool isPlaying: status === "Playing"
    readonly property bool hasTrack: title.length > 0 || artUrl.length > 0
    readonly property bool hasPlayer: playerName.length > 0

    // Co-located with the shell: monoshell/utils/scripts/cava-overlay.sh
    readonly property string cavaScript: Quickshell.shellDir + "/utils/scripts/cava-overlay.sh"

    // Unit separator --- titles/artists can contain | and commas
    readonly property string sep: "\x1f"

    function normalizeArt(url) {
        if (!url || !url.length)
            return ""
        let u = url.trim()
        // Spotify legacy host
        if (u.indexOf("https://open.spotify.com/image/") === 0)
            u = u.replace("https://open.spotify.com/image/", "https://i.scdn.co/image/")
        if (u.indexOf("http://open.spotify.com/image/") === 0)
            u = u.replace("http://open.spotify.com/image/", "https://i.scdn.co/image/")
        if (u.indexOf("http://") === 0)
            u = "https://" + u.substring("http://".length)
        // Some clients return bare scdn hashes
        if (u.length === 40 && u.indexOf("://") < 0 && u.indexOf("/") < 0)
            u = "https://i.scdn.co/image/" + u
        return u
    }

    function refresh() {
        metaProc.running = true
        cavaStatusProc.running = true
    }

    function playPause() {
        ctlProc.args = ["play-pause"]
        ctlProc.running = true
    }
    function next() {
        ctlProc.args = ["next"]
        ctlProc.running = true
    }
    function previous() {
        ctlProc.args = ["previous"]
        ctlProc.running = true
    }

    function setCava(on) {
        cavaToggle.mode = on ? "on" : "off"
        cavaToggle.running = true
    }

    function toggleCava() {
        // flip optimistically; status poll corrects
        cavaToggle.mode = "toggle"
        cavaToggle.running = true
    }

    Process {
        id: metaProc
        // YTM desktop / chromium YTM / Spotify / anything
        // playerctl -l names vary: "spotify", "chromium", "YoutubeMusic", etc.
        command: [
            "bash", "-c",
            "S=$'\\x1f'; "
            + "fmt=\"{{playerName}}${S}{{status}}${S}{{xesam:title}}${S}{{xesam:artist}}${S}{{xesam:album}}${S}{{mpris:artUrl}}\"; "
            + "pick() { playerctl -p \"$1\" metadata --format \"$fmt\" 2>/dev/null; }; "
            + "out=''; "
            + "for p in $(playerctl -l 2>/dev/null); do "
            + "  pl=$(echo \"$p\" | tr '[:upper:]' '[:lower:]'); "
            + "  case \"$pl\" in "
            + "    *youtube*|*ytm*|*ytmusic*|youtube-music*|chromium*) out=$(pick \"$p\"); [ -n \"$out\" ] && break ;; "
            + "  esac; "
            + "done; "
            + "if [ -z \"$out\" ]; then "
            + "  for p in $(playerctl -l 2>/dev/null); do "
            + "    pl=$(echo \"$p\" | tr '[:upper:]' '[:lower:]'); "
            + "    case \"$pl\" in *spotify*) out=$(pick \"$p\"); [ -n \"$out\" ] && break ;; esac; "
            + "  done; "
            + "fi; "
            + "if [ -z \"$out\" ]; then out=$(playerctl metadata --format \"$fmt\" 2>/dev/null || true); fi; "
            + "printf '%s' \"$out\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text
                if (!line || !line.length) {
                    root.playerName = ""
                    root.status = "Stopped"
                    root.title = ""
                    root.artist = ""
                    root.album = ""
                    root.artUrl = ""
                    return
                }
                const parts = line.split(root.sep)
                root.playerName = (parts[0] || "").trim()
                root.status = (parts[1] || "Stopped").trim()
                root.title = (parts[2] || "").trim()
                root.artist = (parts[3] || "").trim()
                root.album = (parts[4] || "").trim()
                root.artUrl = root.normalizeArt((parts[5] || "").trim())
            }
        }
    }

    Process {
        id: ctlProc
        property var args: ["play-pause"]
        command: ["playerctl"].concat(args)
        onExited: metaProc.running = true
    }

    Process {
        id: cavaToggle
        property string mode: "toggle"
        command: ["bash", root.cavaScript, mode]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                root.cavaOn = (s === "on")
                Globals.cavaOverlay = root.cavaOn
            }
        }
        onExited: cavaStatusProc.running = true
    }

    Process {
        id: cavaStatusProc
        command: ["bash", root.cavaScript, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                root.cavaOn = (s === "on")
                Globals.cavaOverlay = root.cavaOn
            }
        }
    }

    Timer {
        interval: Tokens.mediaPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        Quickshell.execDetached(["chmod", "+x", root.cavaScript])
        refresh()
    }
}
