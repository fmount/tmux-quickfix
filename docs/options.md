## Options

Customize `tmux-quickfix` by placing options in `.tmux.conf` and reloading Tmux
environment, or you can simply overwrite these parameters inside the active tmux session

> How can I modify the default size?

    set -g @quickfix-perc-size '20'

> Can I have the sidebar on the top?

    set -g @quickfix-position 'top'

> I don't like the default 'prefix + z' key binding. Can I change it to be 'prefix + e'?

    set -g @quickfix-key 'e'


> I don't like working with percentual size, I'd like to specify the absolute height of the pane!

    set -g @quickfix-height '30'


### Notes

These commands needs to be tested and improved. 
