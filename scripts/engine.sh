get_tmux_option() {
	local option=$1
	local default_value=$2
	#local option_value=$(tmux show-option -sqv "$option")
	local option_value=$(tmux show-option -qv "$option")
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
	#tmux set-option -sq "$option" "$value"
	tmux set-option -q "$option" "$value"
}


set_tmux_option() {
	local option=$1
	local value=$2
	local session=$3
	#tmux set-option -sq  -t "$session" "$option" "$value"
	tmux set-option -q  -t "$session" "$option" "$value"
}


unset_tmux_option() {
	local option_name=$1
	tmux set-option -u "$option_name"
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

get_window_info() {
	local win_index="$1"
	tmux list-windows -F '#{window_index}:#{window_id}:#{pane_id}' | grep "$win_index"
}


get_qfix_info() {
	local quickfix_info
	quickfix_info="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}")"
	
	echo "$quickfix_info"
}

get_qfix_id_by() {
	local id
	ch=$1
	case ${ch} in
		pane_id)
			id=$(get_qfix_info | cut -d ':' -f3)
			echo "$id"
			;;
		win_id)
			id=$(get_qfix_info | cut -d ':' -f2)
			echo "$id"
			;;
		win_index)
			index=$(get_qfix_info | cut -d ':' -f1)
			echo "$index"
			;;
		default)
			index=${QUICKFIX_DEFAULT_WIN_INDEX}
			echo "$index"
			;;
	esac
}


kill_win() {
	win_id="$1"
	tmux killw -t "${win_id}"
}


kill_pan() {
	pan_id="$1"
	tmux killp -t "${pan_id}"
}

# Executed by the main bash when we need to put the quick
# in FG. 
quickfix_join_pane() {
	
	size="$1"
	
	[ -n "$size" ] && size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	
	tmux join-pane -l "${size}" -s "$(get_qfix_id_by 'pane_id')"
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


#command_exists() {
#	local command="$1"
#	type "$command" >/dev/null 2>&1
#}


#quickfix_user_command() {
#	get_tmux_option "$QUICKFIX_COMMAND_OPTION" ""
#}


#quickfix_command() {
#	local user_command="$(quickfix_user_command)"
#	if [ -n "$user_command" ]; then
#		echo "$user_command"
#	fi
#}


quickfix_command_enqueue() {
	echo "ENQUEUE"
	cmd="$1"
	queue="$(get_tmux_option "$QUICKFIX_COMMAND_QUEUE")"
	if [ -n "$queue" ]; then
		echo "$cmd" >> "${queue}"
	else
		echo "$cmd" >> "${QUICKFIX_DEFAULT_CMD_QUEUE}"
	fi
}


exec_cmd() {
	local cmd
	cmd="$1"
	
	#TODO: If no processes are executed inside the quickfix we can send this
	qf="$(get_qfix_id_by 'pane_id')"
	tmux send-keys -t "$qf" "'$cmd'" Enter
}


quickfix_cmd_dequeue() {
	echo "DEQUEUE"
	queue="$(get_tmux_option "$QUICKFIX_COMMAND_QUEUE")"
	current=$(tail -n1 "$queue" && sed '$d' "$queue")
	exec_cmd "$current"
}


have_child() {
	target_pid="$1"
	PGREP=$(which pgrep)
	pg="$("$PGREP" -P "$target_pid")"
	echo "$pg"
}


check_process() {

	local session
	session="$(get_target_session)"
	pane="$(get_qfix_id_by 'pane_id')"
	main_pid=$(tmux list-panes -s -F '#{pane_id}:#{pane_pid}' -t "$session" | grep "$pane" | cut -d ':' -f2)
	if [ ! -z "$main_pid" ]; then
		have_child "$main_pid"
	fi
}


quick_process_tree() {
	local s
	s=$(get_target_session)	
#for s in $(tmux list-sessions -F '#{session_name}') ; do
	echo -e "\ntmux session name: $s\n--------------------"
	for p in $(tmux list-panes -s -F '#{pane_pid}' -t "$s") ; do
		pstree -p -a -A "$p"
	done
#done	
}
