#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

source "$SCRIPTS_DIR/engine.sh"
source "$SCRIPTS_DIR/variables.sh"
source "$SCRIPT_DIR/session.sh"

META_OPTIONS=(
	"${QUICKFIX_KEY_PREFIX}":"${QUICKFIX_DEFAULT_KEY}"
	"${QUICKFIX_KEY_PREFIX-$QUICKFIX_DEFAULT_KEY}:${QUICKFIX_DEFAULT_COMMAND}"
	"${QUICKFIX_POSITION}:${QUICKFIX_DEFAULT_POSITION}"
	"${QUICKFIX_HEIGHT_OPTION}:${QUICKFIX_DEFAULT_HEIGHT}"
	"${QUICKFIX_PERC_OPTION}:${QUICKFIX_DEFAULT_PERC_SIZE}"
)

register_qfix_options() {
	
	local quickfix_command="$SCRIPTS_DIR/quickfix.sh"
	local quickfix_key="$QUICKFIX_DEFAULT_KEY"

	for option in "${META_OPTIONS[@]}"; do
		key="${option%%:*}"
		value="${option##*:}"
		#printf "%s likes to %s.\n" "$key" "$value"
		set_tmux_option "$key" "$value"
	done

	tmux bind-key "${quickfix_key}" run-shell "${quickfix_command}"
}



main() {
	register_qfix_options
}
main
