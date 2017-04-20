Tmux quickfix plugin
---

This is yet another tmux plugin trying to get some useful features from the vim @world.
This plugin allow tmux to have an hidden pane on the current session and use it to do something
(try to imagine why the quickfix in vim is useful for you).

My final goal is to enable tmux to run Async jobs and execute them into the quickfix hidden pane.


Configurable parameters
---

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
|QUICKFIX_DEFAULT_KEY       | z | [leader]+[key] to send back/front the quickfix pane |
|QUICKFIX_DEFAULT_PER_SIZE  | 20 | Default perc size (it has more priority than height value) |
|QUICKFIX_DEFAULT_POSITION  | bottom  | Default position: bottom/top are the only allowed values |
|QUICKFIX_DEFAULT_INPUT   | direct  | method to enqueue commands that should be executed: allowed values: [direct|queue] |
|QUICKFIX_CMD_QUEUE_BASENAME  | queue.cmd  | basename of the temp enqueue/dequeue resource to get commands that should be executed |


- [customization options](docs/options.md)


Manual install
---

Clone the repo:

    $ git clone https://github.com/fmount/tmux-quickfix ~/clone/path

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/clone/path/quickfix.tmux

Reload TMUX environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf

You should now be able to use the plugin.

Install using tpm
----
Simply add to the tpm section of .tmux.conf:

    set -g @plugins 'fmount/tmux-quickfix'


Test Direct method
---
sh1$
\> echo "time ping www.example.com" | xsel -i -p

then exec [prefix] + z 

#TODO: Insert gif as example..


Test Queue method
----


WORK IN PROGRESS...
----

Next steps:

+ make the plugin installable by tpm
+ enable queue backend to process commands
