#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS_DIR="$CURRENT_DIR/scripts"
QUEUE_HOME="$CURRENT_DIR/queue"
BIN="$CURRENT_DIR/bin"

source "$SCRIPTS_DIR/engine.sh"
source "$SCRIPTS_DIR/variables.sh"
source "$SCRIPTS_DIR/session.sh"

META_OPTIONS=(
	"${QUICKFIX_POSITION}:${QUICKFIX_DEFAULT_POSITION}"
	"${QUICKFIX_PERC_OPTION}:${QUICKFIX_DEFAULT_PERC_SIZE}"
	"${QUICKFIX_COMMAND_INPUT}:${QUICKFIX_DEFAULT_CMD_INPUT}"
	"${QUICKFIX_BUFFER_RESERVED}:${QUICKFIX_DEFAULT_BUFFER_RESERVED}"
	
	#"${QUICKFIX_COMMAND_QUEUE}:${QUEUE_HOME}/${QUICKFIX_CMD_QUEUE_BASENAME}"
	#"${QUICKFIX_BUFFER}:${QUICKFIX_DEFAULT_BUFFER_NAME}"
)

register_qfix_options() {
	
	local quickfix_command="$SCRIPTS_DIR/quickfix.sh"
	local quickfix_sendcommand="$BIN/send_command"
	
	local quickfix_key="$QUICKFIX_DEFAULT_KEY"
	local quickfix_sendkey="$QUICKFIX_DEFAULT_SENDKEY"

	for option in "${META_OPTIONS[@]}"; do
		key="${option%%:*}"
		value="${option##*:}"
		set_tmux_option "$key" "$value" "global"
	done

	tmux bind-key "${quickfix_key}" run-shell "${quickfix_command}"
	tmux bind-key "${quickfix_sendkey}" run-shell "${quickfix_sendcommand}"
}


main() {
	register_qfix_options
}
main
