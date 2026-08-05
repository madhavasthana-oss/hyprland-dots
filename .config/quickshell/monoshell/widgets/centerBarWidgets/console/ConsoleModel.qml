/*
  Console launcher entries:
  title, classification, description, icon, execCmd
*/
import QtQuick

Item {
    id: root

    property alias codexModel: codexData

    ListModel {
        id: codexData

        ListElement {
            title: "Ghostty"
            classification: "Terminal"
            description: "GPU-accelerated terminal. Default shell host."
            icon: "com.mitchellh.ghostty"
            execCmd: "ghostty"
        }

        ListElement {
            title: "Kitty"
            classification: "Terminal"
            description: "Lightweight GPU terminal. Fallback if Ghostty is heavy."
            icon: "kitty"
            execCmd: "kitty"
        }

        ListElement {
            title: "Firefox"
            classification: "Browser"
            description: "Web browser."
            icon: "firefox"
            execCmd: "firefox"
        }

        ListElement {
            title: "Dolphin"
            classification: "Files"
            description: "File manager for browsing and managing the filesystem."
            icon: "org.kde.dolphin"
            execCmd: "dolphin"
        }

        ListElement {
            title: "Music"
            classification: "Media"
            description: "YouTube Music desktop player."
            icon: "multimedia-audio-player"
            execCmd: "youtube-music-desktop-app"
        }

        ListElement {
            title: "Neovim"
            classification: "Editor"
            description: "Terminal text editor. Opens in Kitty."
            icon: "nvim"
            execCmd: "kitty -e nvim"
        }

        ListElement {
            title: "Grok"
            classification: "AI"
            description: "Grok CLI assistant. Opens in Kitty."
            icon: "grok"
            execCmd: "kitty -e grok"
        }
    }
}
