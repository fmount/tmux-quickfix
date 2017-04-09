get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}


set_tmux_id() {
	local option=$1
	local value
	value=$(echo "$2" | sed 's/ /_/g' | cut -d '_' -f1)
	tmux set-option -g "$option" "$value"
}


set_tmux_option() {
	local option=$1
	local value=$2
	tmux set-option -gq "$option" "$value"
}


stored_key_vars() {
	tmux show-options -g |
		\grep -i "^${VAR_KEY_PREFIX}-" |
		cut -d ' ' -f1 |               # cut just the variable names
		xargs                          # splat var names in one line
}

# get the key from the variable name
get_key_from_option_name() {
	local option="$1"
	echo "$option" |
		sed "s/^${VAR_KEY_PREFIX}-//"
}

get_value_from_option_name() {
	local option="$1"
	echo "$(get_tmux_option "$option" "")"
}

get_pane_info() {
	local pane_id="$1"
	local format_strings="#{pane_id},$2"
	tmux list-panes -t "$pane_id" -F "$format_strings" |
		\grep "$pane_id" |
		cut -d',' -f2-
}


command_exists() {
	local command="$1"
	type "$command" >/dev/null 2>&1
}


quickfix_user_command() {
	get_tmux_option "$QUICKFIX_COMMAND_OPTION" ""
}


quickfix_key() {
	get_tmux_option "$QFX_OPTION" "$QFX_KEY"
}


quickfix_position() {
	get_tmux_option "$QUICKFIX_POSITION" "$QUICKFIX_DEFAULT_POSITION"
}


quickfix_height() {
	get_tmux_option "$QUICKFIX_HEIGHT_OPTION" "$QUICKFIX_DEFAULAT_HEIGHT"
}


quickfix_command() {
	local user_command="$(quickfix_user_command)"
	if [ -n "$user_command" ]; then
		echo "$user_command"
	elif command_exists "quickfix"; then
		echo "$QUICKFIX_COMMAND"
	else
		echo "$custom_quickfix_command"
	fi
}
