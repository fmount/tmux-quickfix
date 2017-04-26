# Queue manager for background jobs

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/engine.sh"
source "$CURRENT_DIR/variables.sh"
source "$CURRENT_DIR/session.sh"

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


gen_queue() {
	if [ -z "$(get_tmux_option "${QUICKFIX_COMMAND_QUEUE}")" ]; then
		qf=$(mktemp ${QUICKFIX_CMD_QUEUE_BASENAME}.XXX$RANDOM)
		set_tmux_option "${QUICKFIX_COMMAND_QUEUE}" "${qf}"
	fi
}


exec_cmd() {
	local cmd
	local pane_id
	cmd="$1"
	pane_id="$2"
	
	#TODO: If no processes are executed inside the quickfix we can send this
	if [ -n "$cmd" ]; then
		tmux send-keys -t "$pane_id" "$cmd" Enter
	fi
}


quickfix_cmd_dequeue() {
	echo "DEQUEUE"
	queue="$(get_tmux_option "$QUICKFIX_COMMAND_QUEUE")"
	current=$(tail -n1 "$queue" 2>/dev/null && sed '$d' "$queue")
	exec_cmd "$current"
}
