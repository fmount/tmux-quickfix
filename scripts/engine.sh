#source "/home/fmount/git/tmux-quickfix/scripts/session.sh"
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QUEUE_HOME="$CURRENT_DIR/../queue"

get_tmux_option() {
	local option=$1
	#local default_value=$2
	#local option_value=$(tmux show-option -sqv "$option")
	local scope="$2"
	local option_value
	
	if [ "$scope" = "local" ]; then
		option_value=$(tmux show-option -qv "$option")
	else
		option_value=$(tmux show-option -gqv "$option")
	fi

	echo "$option_value"
}


set_tmux_id() {
	local option=$1
	local value
	value=$(echo "$2" | sed 's/ /_/g' | cut -d '_' -f1)
	tmux set-option -q "$option" "$value"
}


set_tmux_option() {
	local option="$1"
	local value="$2"
	local session="$3"
	local scope="$4"

	if [ "$scope" = "local" ]; then
		tmux set-option -q  -t "$session" "$option" "$value"
	else
		tmux set-option -gq "$option" "$value"
	fi

}


unset_tmux_option() {
	local option_name=$1
	local scope="$2"
	if [ "$scope" = "local" ]; then
		tmux set-option -u "$option_name"
	else	
		tmux set-option -gu "$option_name"
	fi
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
	quickfix_info="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "local")"
	
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

## Buffers management

save_buffer() {
	TMUX_BUF="$(get_tmux_option "${QUICKFIX_BUFFER}" "local")"
    [[ ! -e "${TMUX_BUF}" ]] && (touch "${TMUX_BUF}";)
	tmux saveb "${TMUX_BUF}"
}


set_buffer_data() {
	data="$1"
	TMUX_BUF="$2"
	[ -z "${TMUX_BUF}" ] && TMUX_BUF="$(get_tmux_option "${QUICKFIX_BUFFER}" "local")"
	
	tmux set-buffer -b "${TMUX_BUF}" "$data"
}


clean_buffer_data() {
	TMUX_BUF="$1"
	[ -z "${TMUX_BUF}" ] && TMUX_BUF="$(get_tmux_option "${QUICKFIX_BUFFER}" "local")"
	
	tmux set-buffer -b "$TMUX_BUF" " "
}


get_buffer_cmd() {
	TMUX_BUF="$1"
	[ -z "${TMUX_BUF}" ] && TMUX_BUF="$(get_tmux_option "${QUICKFIX_BUFFER}" "local")"
	tmux show-buffer -b "$TMUX_BUF"
}


get_current_buffer_cmd() {
	tmux show-buffer
}


# Executed by the main bash when we need to put the quick
# in FG. 
quickfix_join_pane() {
	
	size="$1"
	
	[ -n "$size" ] && size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	
	tmux join-pane -l "${size}" -s "$(get_qfix_id_by 'pane_id')"
}


quickfix_position() {
	get_tmux_option "${QUICKFIX_POSITION}" "local"
}


### QUEUE AND PROCESSES HANDLING SECTION ###

have_child() {
	target_pid="$1"
	PGREP=$(which pgrep)
	pg="$("$PGREP" -P "$target_pid")"
	echo "$pg"
}


check_process() {

	local session
	session="$(get_current_session)"
	pane="$(get_qfix_id_by 'pane_id')"
	
	main_pid=$(tmux list-panes -s -F '#{pane_id}:#{pane_pid}' -t "$session" | grep "$pane" | cut -d ':' -f2)
	if [ ! -z "$main_pid" ]; then
		have_child "$main_pid"
	fi
}


pidof_quick() {
	local session
	session="$(get_current_session)"
	pane="$1"
	main_pid=$(tmux list-panes -s -F '#{pane_id}:#{pane_pid}' -t "$session" | grep "$pane" | cut -d ':' -f2)
	echo "$main_pid"
}


quick_process_tree() {
	local s
	s=$(get_target_session)	
	echo -e "\ntmux session name: $s\n--------------------"
	for p in $(tmux list-panes -s -F '#{pane_pid}' -t "$s") ; do
		pstree -p -a -A "$p"
	done
}


quickfix_command_enqueue() {
	cmd="$1"
	queue="$2"
	if [ -n "$queue" ]; then
		echo "$cmd" >> "${queue}"
	fi
}


gen_multi_queue() {
	if [ -z "$(get_tmux_option "${QUICKFIX_COMMAND_QUEUE}" "local")" ]; then
		qf=$(mktemp "${QUICKFIX_CMD_QUEUE_BASENAME}".XXX$RANDOM)
		set_tmux_option "${QUICKFIX_COMMAND_QUEUE}" "${qf}" "local"
	fi
}

gen_queue() {
	local session_name="$1"
	#files=(/${QUEUE_HOME}/*)
	#if [ ${#files[@]} -eq 0 ]; then
	touch "${QUEUE_HOME}/${QUICKFIX_CMD_QUEUE_BASENAME}.$session_name"
	set_tmux_option "${QUICKFIX_COMMAND_QUEUE}" "${QUEUE_HOME}"/"${QUICKFIX_CMD_QUEUE_BASENAME}.$session_name" "$session_name" "local"

}

gen_buffer() {
	local session_name="$1"
	set_tmux_option "${QUICKFIX_BUFFER}" "${QUICKFIX_DEFAULT_BUFFER_NAME}.$session_name" "$session_name" "local"
}


exec_cmd() {
	local cmd
	local pane_id
	local mode

	cmd="$1"
	pane_id="$2"
	mode="$3"


	case "$mode" in
		"direct")
			buffer="$(get_tmux_option "${QUICKFIX_BUFFER}")"
			if [ -n "$buffer" ]; then
				# Use the default buffer specified in the options
				tmux send-keys -t "$pane_id" "$(get_buffer_cmd "$buffer")" Enter;
				clean_buffer_data
			else
				tmux send-keys -t "$pane_id" "$(get_current_buffer_cmd)" Enter;
				tmux delete-buffer
			fi
			;;
			
		"queue") 
			if [ -n "$cmd" ]; then
				tmux send-keys -t "$pane_id" "$cmd" Enter;
			fi
			;;
		"default") 
			tmux display-message "Error executing command";
			;;
	esac
}


quickfix_cmd_dequeue() {
	queue="$1"
	current=$(tail -n1 "$queue" 2>/dev/null && sed -i '$d' "$queue")
	echo "$current"
}


# Utility used to debug some without affect the behaviour of the plugin
quickfix_code_debug() {
	msg="$1"
	
	target="${QUICKFIX_DEBUG_LOG}"
	timestamp="$(date +%T)"
	function_caller="${FUNCNAME[1]}"
	
	echo "$timestamp - $function_caller - $msg " >> "$target"
}
