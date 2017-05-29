Tmux quickfix plugin
---

This is yet another tmux plugin trying to get some useful features from the vim @world.
This plugin allow tmux to have a hidden pane on the current session and use it to do something
(try to imagine why the quickfix in vim is useful for you).

**Table of Contents**

- [Tmux quickfix plugin - Intro](#)
- [Configurable parameters](#configurable-parameters)
- [Manual Install](#manual-install)
- [Install using tpm](#install-using-tpm)
- [Test direct method](#test-direct-method)
- [Test queue method](#test-queue-method)
- [Sending commands](#sending-commands)
- [The queue mode](#the-queue-mode)
- [The dequeue job](#the-dequeue-job)
- [Direct mode](#direct-mode)
- [Direct mode with reserved buffer](#direct-mode-with-reserved-buffer)
- [Make mode](#make-mode)
- [Debug mode](#debug-mode)
- [Conclusion](#conclusion)
- [License](#license)


Tmux quickfix plugin - Intro
----

The final goal is to enable tmux to run Async jobs and execute them into the quickfix hidden pane
(that reminds the vim quickfix window).
The main feature related to this work is to allow users to send commands in a separated pane, setting the preferred method to send commands to be processed, so we have a two different kind of approaches: _direct_ and _queue_.


Configurable parameters
---

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
|QUICKFIX_DEFAULT_KEY       | z | [leader]+[key] to send back/front the quickfix pane |
|QUICKFIX_DEFAULT_SEND_CMD_KEY  | a | [leader]+[key] to send a command to the buffer/queue |
|QUICKFIX_DEFAULT_PER_SIZE  | 20 | Default perc size (it has more priority than height value) |
|QUICKFIX_DEFAULT_POSITION  | bottom  | Default position: bottom/top are the only allowed values |
|QUICKFIX_DEFAULT_WIN_INDEX | 42  | Index value of the quickfix window [it should be gt 10 ]  |
|QUICKFIX_DEFAULT_INPUT     | direct  | method to enqueue commands that should be executed: allowed values: [direct|queue] |
|QUICKFIX_CMD_QUEUE_BASENAME| queue.cmd  | basename of the temp enqueue/dequeue resource to get commands that should be executed |
|QUICKFIX_DEBUG_LOG         | quickfix-plugin.log | log file for debug purposes |
|QUICKFIX_DEFAULT_BUFFER    | tmbuf        | default buffer basename to send direct commands to qfix |
|QUICKFIX_DEFAULT_BUFFER_RESERVED          | no        | when the direct mode is enabled we can use a reserved buffer to send/execute_from commands or the system one |
|TMUX_VERSION_ALLOWED       | 2.2        | base tmux version to make this plugin work  |


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

Press `prefix` + <kbd>I</kbd> (capital I, as in **I**nstall) to fetch the plugin.

The plugin was cloned to `~/.tmux/plugins/` dir and sourced.


Test Direct method
---

    sh_main_pane$
    \> tmux setb -b tmbuf "ping -c3 127.0.0.1"

then: [prefix] + z

[![asciicast](https://asciinema.org/a/2gb9r5jgikcqk61dptnieuk6i.png)](https://asciinema.org/a/2gb9r5jgikcqk61dptnieuk6i?autoplay=1)



Test Queue method
---

First of all we need to set the **@quickfix-cmd-input** tmux global option to **queue**.
You can do this running this:

        tmux set-option -g @quickfix-cmd-input "queue"

or modifying the same value in the **variable.sh** script. <br>
I recommend  to start from a fresh environment, sourcing the .tmux.conf and the related plugins
because even if modifying a global metadata generally work, you can experience some bugs related
either the plugin or the tmux version or the combo between them for a specific release. <br>
When the plugin starts in queue mode, users first need to create the quickfix window toggling it
(when you send [prefix+z] for the first time the quickfix is created in background on index 42);
after that a run_queuer process is run by the main tmux zsh/bash process on the shared resource
(**queue.cmd.$session\_id**) and you can test it copying a set of commands simply using the provided
example (~/.tmux/plugins/tmux-quickfix/queue/queue.cmd.example):

        cp ~/.tmux/plugins/tmux-quickfix/queue/queue.cmd.example \
            ~/.tmux/plugins/tmux-quickfix/queue/queue.cmd.$session_id

In the queue mode, toggling the quickfix window doesn't kill it but sends it in background.

[![asciicast](https://asciinema.org/a/bn8holc9f3ic21k8f83yppqm5.png)](https://asciinema.org/a/bn8holc9f3ic21k8f83yppqm5?autoplay=1)

Users can also enqueue commands in the shared queue simply entering copy mode, selecting the command
to send and once it's in the buffer, it can send on the queue using the **send\_command** script defined on
the [prefix]+a keybinding.


Sending Commands
----

The approach to send a command is related to the global configuration of the plugin and it executes
a **send\_command** script located in the bin/ folder.<br>
The send_command script reflects the global state of the plugin, so it needs to consider the value
of the QUICKFIX_COMMAND_INPUT global parameter; afterwards, starting from this value that
we're going to call **mode**, it also evaluates the dependency tree in which the root is the *working mode*.
For instance, if we start in the default mode (direct), we have a \*rleft dependency tree composed as:


                         'direct'                   'queue'
                            /                         /
                           /                         /
                          /                         /
                    'reserved_buffer'      'cmd_queue_basename'
                        /
                       /
                      /
               'buffer_basename'


According to this, the send_command process puts in the correct stack the next job to execute and then
toggling the quickfix window the engine, considering the configuration tree, lead the scheduling
of the **exec\_cmd**.


        ----------                           |----- >      DIRECT BUFFER
        -        -         ------------                                       ----------------
        -  MAIN  - ---- >  shared_queue      |----- >      SHARED QUEUE       engine::exec_cmd
        -        -         ------------                                       ----------------
        ----------                           |----- >      RESERVED BUFFER

The default key to send commands is **[prefix]+a**:

        tmux bind-key a run-shell /path/to/quickfix/scripts/bin/send_command


The queue mode
----

In my opinion this is the most interesting section because the _queue mode_ represent the designed
approach to execute _async_ commands.
By design, a simple structure identified by a shared queue file is defined at _tmux session_ level using
the format *basename.session\_id*.

The following schema reflects the logical path of the commands from the generation to the real
execution:

            ----------                                              -----------------
            -  MAIN  -   enqueue      -------------    dequeue      -   quickfix    -
            -        - ----------- >  shared_queue   ---------- >   -  run_queuer   -
            -  PID   -                -------------                 -    process    -
            ----------                                              -----------------


As the schema shows, users can send command on the shared queue; when the quickfix is opened for
the first time (prefix+z) a job listener is registered on the main pid (third parameter of the run_queuer)
and according to the specified timeout it tries to perform a **dequeue** on the registered shared
resource. <br>

Let's do a practical example; imagine that the current user of our tmux session would like
to enqueue the following command:

    ping -c3 good.old.chicken.killer.com

The steps he just simply perform are:

1. Enter tmux copy mode and select/copy the command above;

2. Once command is inside the tmux default buffer, with [prefix+a] it will be enqueued
  in the defined queue;

3. Toggling the quickfix, the user can see the process executing: in background, the run_queuer
  process orchestrate the dequeue and the execution of the command (see next section).

Unlike the direct mode, the toggle function doesn't kill the quickfix window when it's sent
to back and no jobs are scheduled (queue is empty).<br>
Finally, when user definitively deletes the current tmux session, the run_queuer job kill itself
in a safe way as described in the [The run_queuer job](#run_queuer_section) section.



The dequeue job
----

A direct consequence of the queue mode is the job that performs the dequeue operation on the shared
resource.

   `./run_queuer {session_id} {quickfix_pane_id} {main_pid} {queue_path}`

As the queue is defined for a specific session, the same thing happens for the run_queuer
process that is up and running with these constraints
**[\$session, \$pane_id, \$pid\_to\_listen, \$target]**, where:

1. **SESSION**: it represents the sessionID to check in order to understand if the current session is
   alive or not; if the session is dead (or the user simply kills it), the run_queuer can end its
   job releasing the allocated resources and finally killing itself (and releasing, also, the
   run_queuer.lock). The run_queuer.lock try to protect the singleton instance of the run_queuer,
   avoiding to run it multiple times on the same session/queue.

2. **PANE\_ID**: the hidden pane containing the quickfix process.

3. **PID-TO-LISTEN-ON**: the main pid is the most important parameter of the run_queuer because it
    checks the current status of this resource and then take the decision to change its state: by
    default the run_queuer tries to perform a job execution, but its state can change into **WAIT**
    if the target_pid has childs; this means that there is at least a job in execution (and it is in
    foreground on the quickfix).

4. **TARGET**: when the run_queuer state isn't WAIT, it tries to perform a dequeue on the
   shared resource and send an exec on the quickfix pane defined: the target represents the shared
   resource.


Direct mode
----

The direct mode is the default for this plugin. As described above, users can enter copy mode and
select/copy the command they would execute.<br>
Starting from this point when the toggling of quickfix is performed (by default with [prefix]+z) the
current active buffer is read and the content is sent to the quickfix that tries to run it.<br>
This is the so-called **blind mode** because the plugin isn't aware of the scheduling of commands or
buffers and tries to run everything is passed by the buffer.<br>
For instance, if we have a condition like this:


          buff0003 "cat ~/mytestfile.md"
          buff0002 "df -hT"
          testbuf  "ssh wanttokill@chickenkiller.com rm -rf /usr/bin "
          buff0001 "tail -f /var/log/myapplication/mylog.log"
          buff0000 "[ $[ $RANDOM % 6 ] == 0 ] && rm -rf / || echo *OH-MY-ZSH*

it executes all commands from buffer003 to buffer0000.

[![asciicast](https://asciinema.org/a/6vt7pg5u6da7n61k0jgvx4dn3.png)](https://asciinema.org/a/6vt7pg5u6da7n61k0jgvx4dn3?autoplay=1)



Direct mode with reserved buffer
----

Using the last method we cannot control the buffers' content: according to the dependency tree
described in [Sending Commands](#send_command) section, we can define in the

`<path_to_plugin>/scripts/variables.sh`

the reservation of a **specific buffer** (we can also customize its name).<br>
Specifying a buffer actually solve the problem of the buffer rotation and it also gives more control
to users; it reduces the automation given from the LIFO way because users need to manually manage
the **send-to-execute** cycle of a specified command with the following steps:


        ----------                                          ------------------
        -        -         ---------------                  -                -
        -  MAIN  - ---- >  reserved_buffer   |-------- >    -  QUICKFIX WIN  -
        -        -         ---------------                  -                -
        ----------                                          ------------------


1. Enter tmux copy mode and *select/copy* the command you want to execute in the quickfix window.
   [prefix]+a to send  the command to the defined buffer (a tmux-display message is displayed on the status bar).

2. Toggle the quickfix window to enable the execution of the command when it goes on foreground.

Just do it following the Test Direct method section.


Make mode
---

Make mode is the new feature came in this plugin on commit [a96ed3c84c](https://github.com/fmount/tmux-quickfix/commit/a96ed3c84ccce81c427a77e1968f3aa0dad030ce)
It's an extension of the previous features, but is also built on two main components:

1. **Project**: it represents the target dir on which we can execute commands; to make this variable
   available on the system, it has been registered in the metadata environment (defined locally for each session) 
   as **@quickfix-project**

2. **Make command**: as described for the project variable, this is just the command to be executed 
   on project target dir. It is defined as **@quickfix-make** and users can change its value according
   to the kind of project they're working on.

This is a new mode of work and as usual, metatada are setted up and queried on every new execution.
Modifying these values:

    tmux set-option @quickfix-project "/target/dir/"

and

    tmux set-option @quickfix-make "make command"

users can obtain the desidered behaviour related to the category of their project. 
An example is show by the following video.


[![asciicast](https://asciinema.org/a/arg8rk97mptlp6qlkoz3zkf13.png)](https://asciinema.org/a/arg8rk97mptlp6qlkoz3zkf13?autoplay=1)



Debug mode
---
For development purposes a debug mode is present and a callable function is exposed by the engine
module.
It's a very simple primitive, so this piece of code:

    quickfix_code_debug() {
            msg="$1"
            target="${QUICKFIX_DEBUG_LOG}"
            timestamp="$(date +%T)"
            function_caller="${FUNCNAME[1]}"
            echo "$timestamp - $function_caller - $msg " >> "$target"
    }

allow devs (or who want to start contributing) to set a "breakpoint" inside the code.
More advanced features for dev targets will come with future releases.


Conclusion
----

This work is the result of a classic day in which I started playing around tmux world, trying to
understand more and more its internals, realizing day by day its powerful features!
There are of course lots of bugs and I hope they will be fix in the next releases.

Press `prefix` + <kbd>I</kbd> (capital I, as in **I**nstall) to fetch the plugin.

The plugin was cloned to `~/.tmux/plugins/` dir and sourced.


TODO
---
+ If queue is empty remove it when the session is destroyed


License
---
[MIT](License)
