# Fusuma::Plugin::Appmatcher [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-appmatcher.svg)](https://badge.fury.io/rb/fusuma-plugin-appmatcher) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-appmatcher.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-appmatcher)

[Fusuma](https://github.com/iberianpig/fusuma) plugin configure per application

* Switch settings by detecting active window.

**NOTE: Currently, fusuma-plugin-applicaion_matcher is available Only X11**

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
Google Chrome
Terminal
Wingpanel
Plank
```

## Add appmatcher properties and application names to config.yml

Add `appmatcher:` property in `~/.config/fusuma/config.yml`.

lines beginning from `#` are comments

### Add `application:` property

* Set the `application:` property in the root of config.yml.

* Under the `application:` property, you can set the `application name` as a property.
  * For example, you can set `:Google-chrome`, `:Alacritty`, `Org.gnome.Nautilus`, and so on.
    * You can find property name's hint, with `$ fusuma-appmatcher -l`
  * If set `global:` as the `application name`, it is used as default configuration.

### Example

* Move the existing `swipe` or `pinch` sections in config.yml under `application:` > `Global:`.

```diff
- swipe:
-   4:
-     up:
-       sendkey: 'LEFTCTRL+LEFTALT+DOWN'
-       keypress:
-         LEFTSHIFT:
-           sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+DOWN'
-     down:
-       sendkey: 'LEFTCTRL+LEFTALT+UP'
-       LEFTSHIFT:
-         sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+UP'
+ application:
+   Global:
+     swipe:
+       4:
+         up:
+           sendkey: 'LEFTCTRL+LEFTALT+DOWN'
+           keypress:
+             LEFTSHIFT:
+               sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+DOWN'
+         down:
+           sendkey: 'LEFTCTRL+LEFTALT+UP'
+           LEFTSHIFT:
+             sendkey: 'LEFTSHIFT+LEFTCTRL+LEFTALT+UP'
+   Google-chrome:
+     swipe:
+       3:
+         left:
+           sendkey: 'LEFTALT+RIGHT'
+         right:
+           sendkey: 'LEFTALT+LEFT'
+         up:
+           sendkey: 'LEFTCTRL+T'
+         down:
+           sendkey: 'LEFTCTRL+W'
+   Alacritty:
+     swipe:
+       3: 
+         up:
+           window: {fullscreen: 'add'}
+         down:
+           window: {fullscreen: 'remove'}
```

### TODO

* [ ] Enable Threshold / Interval Settings

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-appmatcher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Appmatcher project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-appmatcher/blob/master/CODE_OF_CONDUCT.md).
