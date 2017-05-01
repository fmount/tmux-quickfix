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
|QUICKFIX_DEFAULT_INPUT     | direct  | method to enqueue commands that should be executed: allowed values: [direct|queue] |
|QUICKFIX_CMD_QUEUE_BASENAME| queue.cmd  | basename of the temp enqueue/dequeue resource to get commands that should be executed |
|QUICKFIX_DEBUG_LOG         | $HOME/quickfix_plugin.log | log file for debug purposes |
|QUICKFIX_BUFFER            | tmbuf        | default buffer to send direct commands to quickfix |

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
    sh_main_pane$
    \> tmux setb -b tmbuf "ping -c3 127.0.0.1"

then: [prefix] + z 

#TODO: Insert gif as example..


Test Queue method
----







WORK IN PROGRESS...
----

Next steps:

+ Fix some includes to be more consistent
+ Fix Queue_home and quickfix_home to work on the .tmux/plugin environment
+ Create a way to enqueue commands both in direct and in queue mode (a bind key could be useful)

