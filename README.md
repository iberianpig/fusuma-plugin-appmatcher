# Fusuma::Plugin::Appmatcher [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-appmatcher.svg)](https://badge.fury.io/rb/fusuma-plugin-appmatcher) [![Build Status](https://github.com/iberianpig/fusuma-plugin-appmatcher/actions/workflows/main.yml/badge.svg)](https://github.com/iberianpig/fusuma-plugin-appmatcher/actions/workflows/main.yml)

[Fusuma](https://github.com/iberianpig/fusuma) plugin configure app-specific gestures

* Switch gesture mappings by detecting active application.
* Support X11, GNOME Wayland, Hyprland, Sway


## Installation

Run the following code in your terminal.

### Install fusuma-plugin-appmatcher

```sh
$ sudo gem install fusuma-plugin-appmatcher
```

### Install Appmatcher GNOME Shell Extensions on Wayland

Gnome Wayland version 41 and later does not allow to access information about window or application like focused app.
So fusuma-plugin-appmatcher solves this problem via Appmatcher gnome-extension.

```sh
$ fusuma-appmatcher --install-gnome-extension
```

Restart your session(logout/login), then activate Appmatcher on gnome-extensions-app

## List Running Application names

`$ fusuma-appmatcher -l` prints Running Application names.

```sh
$ fusuma-appmatcher -l
Slack
Google-chrome
Alacritty
```

You can use these application name to under `application:` context in config.yml

## Add appmatcher properties and application names to config.yml

1. Add the `---` symbol to separate the context in config.yml.

2. Add `context:` property in `~/.config/fusuma/config.yml`.

3. Under the `context:` property, you can set the `application: APP_NAME` as a value.
  * In this context, you can configure mappings to application-specific gestures.
  * For example, you can set `:Google-chrome`, `:Alacritty`, `Org.gnome.Nautilus`, and so on.
  * You can find property name's hint, with `$ fusuma-appmatcher -l`

**NOTE: The first context separated by `---` is the default context**

### Example

In the following example of config.yml

* On Google-chrome, the three-finger gesture is mapped to open in tab, close tab, back in history, forward in history.
* On Gnome-terminal, the three-finger gesture will be mapped to open in tab, close in tab.

```yaml
# this is default context
swipe:
  4:
    up:
      sendkey: 'LEFTCTRL+LEFTALT+DOWN'
      keypress:
        LEFTSHIFT:
          sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+DOWN'
    down:
      sendkey: 'LEFTCTRL+LEFTALT+UP'
      LEFTSHIFT:
        sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+UP'
---
context:
  application:  Google-chrome
swipe:
  3:
    left:
      sendkey: 'LEFTALT+RIGHT'
    right:
      sendkey: 'LEFTALT+LEFT'
    up:
      sendkey: 'LEFTCTRL+T'
    down:
      sendkey: 'LEFTCTRL+W'
---
context:
  application:  Gnome-terminal
swipe:
  3: 
    up:
      sendkey: 'LEFTSHIFT+LEFTCTRL+T'
    down:
      sendkey: 'LEFTSHIFT+LEFTCTRL+W'
```

## Multiple Applications (OR condition)

**Requires fusuma v3.12.0 or later**

You can specify multiple applications using array format. The gesture will be triggered when **any** of the listed applications is active.

```yaml
---
context:
  application:
    - Google-chrome
    - Firefox
swipe:
  3:
    left:
      sendkey: 'LEFTALT+RIGHT'
    right:
      sendkey: 'LEFTALT+LEFT'
    up:
      sendkey: 'LEFTCTRL+T'
    down:
      sendkey: 'LEFTCTRL+W'
```

## Combining with Other Context Plugins (AND condition)

**Requires fusuma v3.12.0 or later**

You can combine `application` with other context conditions. When multiple keys are specified under `context:`, **all** conditions must be satisfied (AND logic).

For example, with [fusuma-plugin-thumbsense](https://github.com/iberianpig/fusuma-plugin-thumbsense):

```yaml
---
context:
  thumbsense: true
  application:
    - Alacritty
    - Gnome-terminal
swipe:
  3:
    up:
      sendkey: 'LEFTSHIFT+LEFTCTRL+T'
    down:
      sendkey: 'LEFTSHIFT+LEFTCTRL+W'
```

In this example, the gesture is only triggered when:
1. Thumbsense mode is active (finger is touching the touchpad)
2. AND the active application is either Alacritty or Gnome-terminal

This AND logic works with any context plugin that provides context conditions

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-appmatcher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

### Help Wanted: Support for Other Wayland Compositors

Currently, this plugin supports X11, GNOME Wayland, Hyprland, and Sway. We'd love to expand support to other Wayland compositors (KDE Plasma, other wlroots-based compositors, etc.).

If you're using an unsupported compositor:
- Please [open an issue](https://github.com/iberianpig/fusuma-plugin-appmatcher/issues) to let us know
- Help with testing and feedback is greatly appreciated

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Appmatcher project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-appmatcher/blob/master/CODE_OF_CONDUCT.md).
