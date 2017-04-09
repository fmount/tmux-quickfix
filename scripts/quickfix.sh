#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/engine.sh"
source "$CURRENT_DIR/variables.sh"

PANE_CURRENT_PATH="$(pwd)"
PANE_ID=""


get_qfix_pane_id() {
	local pane_id
	pane_id="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}")"
	
	echo "$pane_id"
}


quickfix_exists() {
	local var
	var="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "")"
	[ -n "$var" ]
}


register_quickfix() {
	local quickfix_info="$1"
	set_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${quickfix_info}"
}


#TODO
join_quick() {
	local main_pane_id
	main_pane_id="$(get_tmux_option "${REGISTERED_QUICKFIX_PREFIX}" "${PANE_ID}" "")" 
	# execute the same command as if from the "main" pane
	"$CURRENT_DIR"/toggle.sh
}


split_qfix() {

	qfix_size=get_tmux_option "${QUICKFIX_PERC_OPTION}"

	[ ! -n "$qfix_size" ] && qfix_size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	
	case $1 in
		"bottom")
			qfix="$(tmux new-window -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}")"
			tmux select-window -l
			tmux join-pane -v -l "$qfix_size" -s "$qfix"
			
			#we need to register this qfix_id to the option world of tmux
			echo "$qfix"
			;;

		"top")
			qfix="$(tmux new-window -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}")"
			tmux select-window -l
			tmux join-pane -v -l "$qfix_size" -s "$qfix"
			
			#we need to register this qfix_id to the option world of tmux
			echo "$qfix"
			;;
	esac
}


create_quickfix	() {
	local position="$1" # top / bottom
	local quickfix_id
	quickfix_id="$(split_qfix "${position}")"
	register_quickfix "$quickfix_id"
	#Check the focus..
}


quickfix_is_fore() {
	local fore
	fore="$(tmux list-panes -F "#{pane_id}" 2>/dev/null | grep "$(get_qfix_pane_id)")"
	[ -n "$fore" ]
}


send_back() {
	#echo "send back"
	tmux break-pane -d -s "$(get_qfix_pane_id)"
}


send_front(){
	#echo "send front"
	size=$(get_tmux_option "${QUICKFIX_PERC_OPTION}")
	
	[ -n "$size" ] && size="${QUICKFIX_DEFAULT_PERC_SIZE}"
	tmux join-pane -l "${size}" -s "$(get_qfix_pane_id)"
	tmux send-key Enter
}


toggle_quickfix() {
	position=$(get_tmux_option "${QUICKFIX_POSITION}")
	
	[ -n "$position" ] && position="${QUICKFIX_DEFAULT_POSITION}"
	
	if quickfix_exists; then
		if quickfix_is_fore; then
			send_back
		else
			send_front
		fi
	else
		create_quickfix "$position"
	fi
}


main(){
	toggle_quickfix
}
main
