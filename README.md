# Fusuma::Plugin::Appmatcher [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-appmatcher.svg)](https://badge.fury.io/rb/fusuma-plugin-appmatcher) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-appmatcher.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-appmatcher)

[Fusuma](https://github.com/iberianpig/fusuma) plugin configure app-specific gestures

* Switch gesture mappings by detecting active application.
* Support X11, Ubuntu-Wayland


## Installation

Run the following code in your terminal.

### Install fusuma-plugin-appmatcher

```sh
$ sudo gem install fusuma-plugin-appmatcher
```

## List Running Application names

`$ fusuma-appmatcher -l` prints Running Application names.

```sh
$ fusuma-appmatcher -l
Slack
Google-chrome
Alacritty
```

You can use these applicatin name to under `application:` context in config.yml

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-appmatcher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Appmatcher project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-appmatcher/blob/master/CODE_OF_CONDUCT.md).
