# ** Metadata/Options **
QUICKFIX_KEY_PREFIX="@quickfix-key"

QUICKFIX_POSITION="@quickfix-position"
QUICKFIX_HEIGHT_OPTION="@quickfix-height"
QUICKFIX_PERC_OPTION="@quickfix-perc-size"
REGISTERED_PANE_PREFIX="@quickfix-registered-pane"
QUICKFIX_COMMAND_QUEUE="@quickfix-cmd-queue"
QUICKFIX_COMMAND_INPUT="@quickfix-cmd-input"
QUICKFIX_BUFFER="@quickfix-buffer"
QUICKFIX_BUFFER_RESERVED="@quickfix-buffer-reserved"

# This is the variable containing all the quickfix informations
# with the form [@winID]:[winIndex]:[%paneID]
REGISTERED_QUICKFIX_PREFIX="@quickfix-id"

QUICKFIX_OPTION="@quickfix-win"

# ** Default options **

QUICKFIX_DEFAULT_PERC_SIZE="20"
QUICKFIX_DEFAULT_KEY="z"
QUICKFIX_DEFAULT_SENDKEY="a"
QUICKFIX_DEFAULT_POSITION="bottom"
QUICKFIX_DEFAULT_WIN_INDEX=42
QUICKFIX_CMD_QUEUE_BASENAME="queue.cmd"
QUICKFIX_DEFAULT_CMD_INPUT="direct" # Allowed values: [direct|queue]
#QUICKFIX_DEFAULT_CMD_INPUT="queue" # Allowed values: [direct|queue]
QUICKFIX_DEFAULT_BUFFER_RESERVED="yes" # Allowed values: [yes|no]
QUICKFIX_DEFAULT_BUFFER_NAME="tmbuf"

QUICKFIX_DEBUG_LOG="$HOME/quickfix-plugin.log"
TMUX_VERSION_ALLOWED="2.2"
