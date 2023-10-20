import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

const DBUS_INTERFACE = `
<node>
    <interface name="dev.iberianpig.Appmatcher">
        <method name="ActiveWindow">
            <arg type="s" direction="out" name="win"/>
        </method>
        <method name="ListWindows">
            <arg type="s" direction="out" name="wins"/>
        </method>
        <signal name="ActiveWindowChanged">
            <arg type="s" name="new_win"/>
        </signal>
    </interface>
</node>`;

export default class AppMatcherExtension extends Extension {
  enable() {
    this._dbus = Gio.DBusExportedObject.wrapJSObject(DBUS_INTERFACE, this);
    this._dbus.export(Gio.DBus.session, '/dev/iberianpig/Appmatcher');
    this._callback_id = global.display.connect('notify::focus-window', ()=> { 
      this.activeWindowChanged()
    })
  }

  disable() {
    this._dbus.flush();
    this._dbus.unexport();
    if (this._callback_id) {
      global.display.disconnect(this._callback_id);
      delete this._callback_id
    }
    delete this._dbus;
  }

  activeWindowChanged() {
    const w = global.display.get_focus_window();
    if(!w) { return; }

    try {
      const obj = { wm_class: w.get_wm_class(), pid: w.get_pid(), id: w.get_id(), title: w.get_title(), focus: w.has_focus()}
      this._dbus.emit_signal('ActiveWindowChanged', new GLib.Variant('(s)', [JSON.stringify(obj)]));
    } catch (e) {
      console.error(e, 'failed to Emit DBus signal');
    }
  }

  ListWindows() {
    const wins = global.get_window_actors()
      .map(a => a.meta_window)
      .map(w => ({ wm_class: w.get_wm_class(), pid: w.get_pid(), id: w.get_id(), title: w.get_title(), focus: w.has_focus()}));
    return JSON.stringify(wins);
  }

  ActiveWindow() {
    const actor = global.get_window_actors().find(a=>a.meta_window.has_focus()===true)
    if(!actor) { return '{}'; }
    const w = actor.get_meta_window()
    try {
      const obj = { wm_class: w.get_wm_class(), pid: w.get_pid(), id: w.get_id(), title: w.get_title(), focus: w.has_focus()}
      return JSON.stringify(obj);
    } catch (e) {
      console.error(e, 'failed to fetch ActiveWindow()');
    }
  }
}
