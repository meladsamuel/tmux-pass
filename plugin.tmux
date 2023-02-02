#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
  tmux bind-key "b" run "tmux popup -w 30% -h 50% -E \"$CURRENT_DIR/scripts/main.sh '#{pane_id}'\""
}

main "$@"
