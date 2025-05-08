#!/usr/bin/env fish

set SESSION_NAME "ghostty"

# Check if the session already exists
if tmux has-session -t $SESSION_NAME 2>/dev/null
  echo "There is a tmux session running"
else
    # If the session doesn't exist, start a new one
    tmux new-session -s $SESSION_NAME -d
    # Run fastfetch in the newly created tmux session
    tmux send-keys -t $SESSION_NAME 'fastfetch' C-m
    tmux attach-session -t $SESSION_NAME
end
