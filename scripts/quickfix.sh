#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/engine.sh"
source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/session.sh"

PANE_CURRENT_PATH="$(pwd)"
PANE_ID=""


get_qfix_info() {
	local quickfix_info
	quickfix_info="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}")"
	
	echo "$quickfix_info"
}


get_qfix_id_by() {
	local id
	criteria=$1
	case ${criteria} in
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


quickfix_exists() {
	local var
	var="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "")"
	[ -n "$var" ]
}


register_quickfix() {
	local quickfix_info="$1"
	local session="$(get_current_session)"
	local quickfix_pane_id="$(echo "${quickfix_info}" | cut -d ':' -f3)"
	local quickfix_designed_index=$(get_qfix_id_by 'default')
	
	#TODO: The win_id is not necessarily the index: fix the building of qfix indexes
	quickfix_info="${quickfix_designed_index}:@-1:${quickfix_pane_id}"
	set_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${quickfix_info}" "${session}"
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

#TODO
join_quick() {
	local main_pane_id
	main_pane_id="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${PANE_ID}" "")" 
	# execute the same command as if from the "main" pane
	"$CURRENT_DIR"/quickfix.sh
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
			
			#we need to register this qfix_id to the option world of tmux
			echo "$info"
			;;

		"top")
			info="$(tmux new-window -c "$PANE_CURRENT_PATH" -n quickfix -P -F "#{window_index}:#{window_id}:#{pane_id}")"
			pane_id=$(echo "$info" | cut -d ':' -f3)
			tmux select-window -l
			tmux join-pane -v -l "$qfix_size" -s "$pane_id"
			
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
	
}


send_front(){
	#echo "send front"
	size=$(get_tmux_option "${QUICKFIX_PERC_OPTION}")
	
	[ -n "$size" ] && size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	
	tmux join-pane -l "${size}" -s "$(get_qfix_id_by 'pane_id')"
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
