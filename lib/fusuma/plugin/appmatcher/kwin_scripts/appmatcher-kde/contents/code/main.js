// KWin script for fusuma-plugin-appmatcher
// This script monitors active window changes and notifies the Ruby backend via DBus

function notifyActiveWindow(client) {
    if (!client) {
        // Ignore when there is no active window
        return;
    }

    callDBus(
        "dev.iberianpig.Appmatcher.KDE",
        "/dev/iberianpig/Appmatcher/KDE",
        "dev.iberianpig.Appmatcher.KDE",
        "NotifyActiveWindow",
        "caption" in client ? client.caption : "",
        "resourceClass" in client ? client.resourceClass : "",
        "resourceName" in client ? client.resourceName : ""
    );
}

// Support both KDE 5 and KDE 6
if (workspace.windowList) {
    // KDE 6
    workspace.windowActivated.connect(notifyActiveWindow);
} else {
    // KDE 5
    workspace.clientActivated.connect(notifyActiveWindow);
}
