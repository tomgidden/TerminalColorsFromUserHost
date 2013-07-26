TerminalColorsFromUserHost
==========================

SIMBL plugin to dynamically change Terminal.app foreground/background color
based on user@host from title

This hack should notice when a tab's title changes in OS X's Terminal.app
and parse it for user@host. Then, using (currently hardcoded) predetermined
values, it'll dynamically change the foreground and background color of
the tab accordingly.

As a result, terminals logged in as "root" get red foreground text, and
logged in as other than "gid" (my standard username) get blue foreground text.
Then, the hostname changes the background colour.

At one point those choices need to be configurable, but this is an early
release :)

To enable the title changes, set something like this in your zshrc:
```
case $TERM in
    xterm*)
        precmd () {print -Pn "\e]0;%n@%m\a"}
        ;;
esac
```
...if you use zsh.  If you use bash or another shell, you're on your own :)

It'll only really be useful (and even usable) if all the machines and shells
you log into have this feature configured.  Otherwise, the colors shown
can be out-of-date and a potentially-dangerous false negative.

Improvements *very* welcome!

