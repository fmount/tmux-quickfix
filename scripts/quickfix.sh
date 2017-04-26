#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$CURRENT_DIR/../bin"

source "$CURRENT_DIR/engine.sh"
source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/session.sh"

PANE_CURRENT_PATH="$(pwd)"


quickfix_exists() {
	local var
	var="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "")"
	[ -n "$var" ]
}


register_quickfix() {
	local session
	local quickfix_pane_id
	local quickfix_designed_index
	local quickfix_info="$1"
	local mode="$2" # direct / queue

	session="$(get_current_session)"
	quickfix_pane_id="$(echo "${quickfix_info}" | cut -d ':' -f3)"
	quickfix_designed_index=$(get_qfix_id_by 'default')
	
	local quickfix_window_id
	[ "$mode" = "direct" ] && quickfix_window_id="@-1" || quickfix_window_id="$(echo "${quickfix_info}" | cut -d ':' -f2)"
	#The win_id is not necessarily the index: set the value to -1 until the 
	#background win is created

	quickfix_info="${quickfix_designed_index}:${quickfix_window_id}:${quickfix_pane_id}"
	set_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${quickfix_info}" "${session}"
}


unregister_quickfix() {
	for element in $(tmux show-options -q | grep quickfix | cut -d " " -f1); do
		unset_tmux_option "$element"
	done	
}


# I can kill the pane when is in foreground, or kill the window
# when the quickfix is in background, so this function accepts
# pane/window as parameters

kill_quickfix() {
	target="$1"
	if [ "$target" = "window" ]; then
		quick_win_id="$(get_qfix_id_by 'win_id')"
		kill_win "$quick_win_id"
		unset_tmux_option "${REGISTERED_QUICKFIX_PREFIX}"
	elif [ "$target" = "pane" ]; then
		quick_pan_id="$(get_qfix_id_by 'pane_id')"
		kill_pan "$quick_pan_id"
		unset_tmux_option "${REGISTERED_QUICKFIX_PREFIX}"
	fi
}


update_quickfix_meta() {
	local new_meta="$1"
	local old_meta
	old_meta=$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}")
	
	if [ "$new_meta" != "$old_meta" ]; then 
		local session
		session="$(get_current_session)"
		set_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${new_meta}" "${session}" 
	fi
}


split_qfix() {

	qfix_size=get_tmux_option "${QUICKFIX_PERC_OPTION}"

	[ ! -n "$qfix_size" ] && qfix_size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	
	local mode="$2" # direct / queue
	local cmd="$3"	

	case $1 in
		"bottom")
			info="$(tmux new-window -c "$PANE_CURRENT_PATH" -n quickfix -P -F "#{window_index}:#{window_id}:#{pane_id}")"
			pane_id=$(echo "$info" | cut -d ':' -f3)
			tmux select-window -l
			if [ "$mode" == "direct" ]; then
				tmux join-pane -v -l "$qfix_size" -s "$pane_id"
				exec_cmd "$cmd" "$pane_id"
			else
				#tmux_queue="$HOME/queue.cmd"
				tmux_queue="$(get_tmux_option "${QUICKFIX_COMMAND_QUEUE}")"
				if [ ! -f "$tmux_queue" ]; then touch "$tmux_queue"; fi
				main_pid="$(pidof_quick "$pane_id")"
				current_session="$(get_current_session)"
				tmux join-pane -v -l "$qfix_size" -s "$pane_id"
				send_back "$mode"
				
				cmd="sh $BIN/run_queuer $current_session $pane_id $main_pid $tmux_queue"
				exec_cmd "$cmd" "$pane_id"
			fi
			
			#we need to register this qfix info to the option world of tmux for this session
			echo "$info"
			;;

		"top")
			info="$(tmux new-window -c "$PANE_CURRENT_PATH" -n quickfix -P -F "#{window_index}:#{window_id}:#{pane_id}")"
			pane_id=$(echo "$info" | cut -d ':' -f3)
			tmux select-window -l
			if [ "$mode" == "direct" ]; then
				tmux join-pane -v -lb "$qfix_size" -s "$pane_id"
				exec_cmd "$cmd" "$pane_id"
			else
				#TODO: get queue from metadata
				#tmux_queue="$HOME/queue.cmd"
				tmux_queue="$(get_tmux_option "${QUICKFIX_COMMAND_QUEUE}")"
				
				main_pid="$(pidof_quick "$pane_id")"
				current_session="$(get_current_session)"
				tmux join-pane -v -l "$qfix_size" -s "$pane_id"
				send_back "$mode"
				
				cmd="sh $BIN/run_queuer $current_session $pane_id $main_pid $tmux_queue"
				exec_cmd "$cmd" "$pane_id"

			fi
			
			#we need to register this qfix_id to the option world of tmux
			echo "$info"
			;;
	esac
}


send_cmd() {
	
	# if the method is direct, copy the command to the clipboard , 
	# if instead the method is queue, we enqueue the command

	input="$1" #direct or queue
	cmd="$2"

  	case $input in
		"queue")
			echo "enqueue command"
			tmux_queue="$(get_tmux_option "${QUICKFIX_COMMAND_QUEUE}")"
			
			#TODO: use mktemp to generate a temp queue to send commands..
			[[ ! -e "$tmux_queue" ]] && (gen_queue; tmux display-message "TMUX queue ($tmux_queue) created.")

			quickfix_command_enqueue "$cmd"
			;;
		"direct")
			cmdw="$(echo "$cmd" | xsel -i -p)"
	  		;;
		*)
			tmux display-message "tmux-quickfix unsupported input method"
			exit
			;;
  	esac

}

create_quickfix	() {
	local position="$1" # top / bottom
	local mode="$2" # direct / queue
	local cmd="$3"
	local quickfix_meta
	#quickfix_meta="$(split_qfix "${position}")"
	
	quickfix_meta="$(split_qfix "${position}" "${mode}" "${cmd}")"
	register_quickfix "$quickfix_meta" "$mode"
}


quickfix_is_fore() {
	local fore
	fore="$(tmux list-panes -F "#{pane_id}" 2>/dev/null | grep "$(get_qfix_id_by 'pane_id')")"
	[ -n "$fore" ]
}


send_back() {
	win_index=$(get_qfix_id_by 'default')
	local mode="$1" # direct / queue

	tmux break-pane -d -t "${win_index}" -s "$(get_qfix_id_by 'pane_id')"
	
	## The adopted method is to use the window_index to set its status format
	## to an empty string: in this way we hide the quickfix
	
	tmux set-window-option -t "${win_index}" window-status-format ""
	quick_meta="$(get_window_info "${win_index}")"
	update_quickfix_meta "$quick_meta"
	
	if [ ! "$(check_process)" ] && [ "$mode" == "direct" ]; then 
		kill_quickfix "pane"
	#else
	#	echo "Cannot kill"
	fi
}


send_front(){
	size=$(get_tmux_option "${QUICKFIX_PERC_OPTION}")
	
	local position="$1"
	local mode="$2"
	local cmd="$3"
	
	#TODO: BUG => the windowID is +1 :/
	#quick_win="$(tmux list-windows -F "#{window_id}" 2>/dev/null | grep "$(get_qfix_id_by 'win_id')")"
	
	quick_win="$(tmux list-windows -F "#{window_index}" 2>/dev/null | grep "$(get_qfix_id_by 'win_index')")"
	
	if [ -n "$quick_win" ]; then
		quickfix_join_pane "$size"
	else
		# Cannot find quickfix win: update meta and redraw
		unset_tmux_option "${REGISTERED_QUICKFIX_PREFIX}"
		create_quickfix "$position" "$mode" "$cmd"
	fi
}


toggle_quickfix() {
	position=$(get_tmux_option "${QUICKFIX_POSITION}")
	
	mode=$(get_tmux_option "${QUICKFIX_COMMAND_INPUT}")
	[ -n "$position" ] && position="${QUICKFIX_DEFAULT_POSITION}"
	
	## THIS IS JUST A TRY
	cmd="$(xsel -p)"
	
	if quickfix_exists; then
		if quickfix_is_fore; then
			send_back "$mode"
		else
			send_front "$position" "$mode" "$cmd"
		fi
	else
		create_quickfix "$position" "$mode" "$cmd"
	fi
	
	# TODO: be sure that buffer is clean
	xsel -c
}


main(){
	toggle_quickfix
}
main
