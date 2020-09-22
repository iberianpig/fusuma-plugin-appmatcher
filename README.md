# Fusuma::Plugin::ApplicationMatcher [![Gem Version](https://badge.fury.io/rb/fusuma-plugin-application_matcher.svg)](https://badge.fury.io/rb/fusuma-plugin-application_matcher) [![Build Status](https://travis-ci.com/iberianpig/fusuma-plugin-application_matcher.svg?branch=master)](https://travis-ci.com/iberianpig/fusuma-plugin-application_matcher)

[Fusuma](https://github.com/iberianpig/fusuma) plugin configure per application

* Switch settings by detecting active window.

**NOTE: Currently, fusuma-plugin-applicaion_matcher is available Only X11**

## Installation

Run the following code in your terminal.

### Install dependencies

```sh
$ sudo apt-get install bamfdaemon
```

### Install fusuma-plugin-application_matcher

```sh
$ sudo gem install fusuma-plugin-application_matcher
```


## List Running Application names

`$ fusuma-application_matcher -l` prints Running Application names.

```sh
$ fusuma-application_matcher -l
Google Chrome
Terminal
Wingpanel
Plank
```

## Add application_matcher properties and application names to config.yml

Add `application_matcher:` property in `~/.config/fusuma/config.yml`.

lines beginning from `#` are comments

### Add `application:` property

* Set the `application:` property in the root of config.yml.

* The `application:` property should be set to `ApplicationName:` underneath the `application:` property.
    * If set `global:` as the `ApplicationName`, it is used when the application is not found.

* Move the `swipe` and `pinch` settings under `ApplicationName:`.


### Example

```diff
- swipe:
-   3:
-     left:
-       sendkey: "LEFTALT+RIGHT" # history back
-     right:
-       sendkey: "LEFTALT+LEFT" # history forward
-     up:
-       sendkey: "LEFTCTRL+T" # open new tab
-     down:
-       sendkey: "LEFTCTRL+W" # close tab
+ application:
+   Global:
+     swipe:
+       3:
+         left:
+           sendkey: "LEFTALT+RIGHT" # history back
+         right:
+           sendkey: "LEFTALT+LEFT" # history forward
+         up:
+           sendkey: "LEFTCTRL+T" # open new tab
+         down:
+           sendkey: "LEFTCTRL+W" # close tab
+   Terminal:
+     swipe:
+       3: 
+         up:
+           window: {fullscreen: 'add'}
+         down:
+           window: {fullscreen: 'remove'}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iberianpig/fusuma-plugin-application_matcher. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::ApplicationMatcher project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/iberianpig/fusuma-plugin-application_matcher/blob/master/CODE_OF_CONDUCT.md).
