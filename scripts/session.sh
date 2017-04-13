#!/usr/bin/env bash

# Manage tmux sessions

get_target_session() {
	local session_id
	session_id=$(tmux list-sessions | grep attached | awk '{print $1}' | cut -d ':' -f1)
	echo "${session_id}"
}


get_attached_sessions() {
	echo "$(tmux list-sessions | sed -n '/(attached)/s/:.*//p')"
}

get_current_session() {
	echo "$(tmux display-message -p "#S")"
}

