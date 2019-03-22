# Useful Rofi Commands

A collection of desktop commands made with [Rofi](https://github.com/DaveDavenport/rofi) for Sway. They can be easily forked and adjusted for another desktops (e.g i3).

## Install

```bash
$ git clone https://github.com/azer/useful-rofi-commands.git
$ export PATH=$PATH:~/useful-rofi-commands # Adjust the path to where you clone the repo at
```

Now the commands documented below will be available in your system.

## Commands

### prompt

Prompt user any question and get an answer. Example:

```bash
prompt -q "How are you today ?" -o "Great,Chill,On fire"
```

It'll launch a simple prompt that will look like:

![](https://cldup.com/LWc-eABFAv.png)

The rest of the commands are basically based on this simple custom Rofi call.

### session-menu

Session menu customized for Sway. It can be tweaked to work with other desktops (i3?) easily.

![](https://cldup.com/zdOW0IReBp.png)

### capture-screen

A menu to shoot screenshots, screencasts and gifcasts. It requires following dependencies specific to Sway:

* [wf-recorder](https://github.com/ammen99/wf-recorder)
* [grim](https://github.com/emersion/grim)

![](https://cldup.com/AlD1AC_TTy.png)
