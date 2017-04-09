Tmux quickfix plugin
---

This is yet another tmux plugin trying to get some useful features from the vim @world.
This plugin allow tmux to have an hidden pane on the current session and use it to do something
(try to imagine why the quickfix in vim is useful for you).

My final goal is to enable tmux to run Async jobs and execute them into the quickfix hidden pane.


###Configurable parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
|QUICKFIX_DEFAULT_KEY       | z | [leader]+[key] to send back/front the quickfix pane |
|QUICKFIX_DEFAULT_HEIGHT    | 30 | Default height of the quickfix pane |
|QUICKFIX_DEFAULT_PER_SIZE  | 20 | Default perc size (it has more priority than height value) |
|QUICKFIX_DEFAULT_POSITION  | bottom  | Default position: bottom/top are the only allowed values |
|QUICKFIX_DEFAULT_COMMAND   | $SCRIPTS_DIR/toggle.sh  | path to command to be executed |


- [customization options](docs/options.md)


###Manual install

Clone the repo:

    $ git clone https://github.com/fmount/tmux-quickfix ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/quickfix.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now be able to use the plugin.


###WORK IN PROGRESS...

Next steps:

+ Hide the window when the quickfix is sent to back;
+ Define a background queue to accept and execute commands;
+ Better test for toggling functions and metadata;

