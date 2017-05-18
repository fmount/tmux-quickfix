#!/usr/bin/env bash

# Manage tmux sessions

get_target_session() {
	local session_id
	session_id=$(tmux list-sessions | grep attached | awk '{print $1}' | cut -d ':' -f1)
	echo "${session_id}"
}


get_attached_sessions() {
	tmux list-sessions | sed -n '/(attached)/s/:.*//p'
}


get_current_session() {
	tmux display-message -p "#S"
}

session_exists() {
	s_target="$1"
	t_target="$(tmux list-session | grep "$s_target": | cut -d ':' -f1)"
	[ "$s_target" = "$t_target" ] && return 0 || return 1
}
