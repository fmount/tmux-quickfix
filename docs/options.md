## Options

Customize `tmux-quickfix` by placing options in `.tmux.conf` and reloading Tmux
environment, or you can simply overwrite these parameters inside the active tmux session

> How can I modify the default size?

    set -g @quickfix-perc-size '20'

> Can I have the quickfix on the top?

    set -g @quickfix-position 'top'


> I don't like working with percentual size, I'd like to specify the absolute height of the pane!

    set -g @quickfix-height '30'


> I just want to change some config specific parameters: how??
    
    ~/.tmux/plugins/tmux-quickfix/script/variables.sh

In the section "Default options" you can change one or more options according to your preferences
(TODO: a global runtime config for these options)
We recommend to fully read the provided README to better understand the meaning of each parameter.

### Notes

These commands needs to be tested and improved. 
