#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/engine.sh"
source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/session.sh"

PANE_CURRENT_PATH="$(pwd)"


quickfix_exists() {
	local var
	local index
	var="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "")"
	[ -n "$var" ]
}


register_quickfix() {
	local session
	local quickfix_pane_id
	local quickfix_designed_index
	local quickfix_info="$1"
	session="$(get_current_session)"
	quickfix_pane_id="$(echo "${quickfix_info}" | cut -d ':' -f3)"
	quickfix_designed_index=$(get_qfix_id_by 'default')
	
	#The win_id is not necessarily the index: set the value to -1 until the 
	#background win is created

	quickfix_info="${quickfix_designed_index}:@-1:${quickfix_pane_id}"
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
		echo "killing window: $quick_win_id"
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
	
	case $1 in
		"bottom")
			info="$(tmux new-window -c "$PANE_CURRENT_PATH" -n quickfix -P -F "#{window_index}:#{window_id}:#{pane_id}")"
			pane_id=$(echo "$info" | cut -d ':' -f3)
			tmux select-window -l
			tmux join-pane -v -l "$qfix_size" -s "$pane_id"
			
			#we need to register this qfix info to the option world of tmux for this session
			echo "$info"
			;;

		"top")
			info="$(tmux new-window -c "$PANE_CURRENT_PATH" -n quickfix -P -F "#{window_index}:#{window_id}:#{pane_id}")"
			pane_id=$(echo "$info" | cut -d ':' -f3)
			tmux select-window -l
			tmux join-pane -v -lb "$qfix_size" -s "$pane_id"
			
			#we need to register this qfix_id to the option world of tmux
			echo "$info"
			;;
	esac
}


create_quickfix	() {
	local position="$1" # top / bottom
	local mode="$2"
	local quickfix_meta
	quickfix_meta="$(split_qfix "${position}")"
	register_quickfix "$quickfix_meta" "$mode"
}


quickfix_is_fore() {
	local fore
	fore="$(tmux list-panes -F "#{pane_id}" 2>/dev/null | grep "$(get_qfix_id_by 'pane_id')")"
	[ -n "$fore" ]
}


send_back() {
	#echo "send back"
	win_index=$(get_qfix_id_by 'default')
	tmux break-pane -d -t "${win_index}" -s "$(get_qfix_id_by 'pane_id')"
	
	## The adopted method is to use the window_index to set its status format
	## to an empty string: in this way we hide the quickfix
	
	tmux set-window-option -t "${win_index}" window-status-format ""
	quick_meta="$(get_window_info "${win_index}")"
	update_quickfix_meta "$quick_meta"
	
	#kill_quickfix "pane"
}


send_front(){
	#echo "send front"
	size=$(get_tmux_option "${QUICKFIX_PERC_OPTION}")
	quickfix_join_pane "$size"
}


toggle_quickfix() {
	position=$(get_tmux_option "${QUICKFIX_POSITION}")
	
	[ -n "$position" ] && position="${QUICKFIX_DEFAULT_POSITION}"
	
	#Work on this param
	mode="default"

	if quickfix_exists; then
		if quickfix_is_fore; then
			send_back
		else
			send_front
		fi
	else
		create_quickfix "$position" "$mode"
	fi
}


main(){
	toggle_quickfix
}
main
