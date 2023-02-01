#!/usr/bin/env bash

main() {

  CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  tmux bind-key "b" run "tmux display-popup \"$CURRENT_DIR/scripts/main.sh '#{pane_id}'\""
}

main "$@"
