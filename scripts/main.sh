#!/usr/bin/env bash

command_found() {
  command -v "$1" &> /dev/null
  return $?
}

copy_to_clipboard() {
  if [[ "$(uname)" == "Darwin" ]] && command_found "pbcopy"; then
    echo -n "$1" | pbcopy
  elif [[ "$(uname)" == "Linux" ]] && command_found "xsel"; then
    echo -n "$1" | xsel -b
  elif [[ "$(uname)" == "Linux" ]] && command_found "xclip"; then
    echo -n "$1" | xclip -i
  else
    return 1
  fi
}

clear_from_clipboard() {
  local -r SEC="$1"
  if [[ "$(uname)" == "Darwin" ]] && is_cmd_exists "pbcopy"; then
    tmux run-shell -b "sleep $SEC && echo '' | pbcopy"
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "xsel"; then
    tmux run-shell -b "sleep $SEC && xsel -c -b"
  elif [[ "$(uname)" == "Linux" ]] && is_cmd_exists "xclip"; then
    tmux run-shell -b "sleep $SEC && echo '' | xclip -i"
  else
    return 1
  fi
}

list_passwords() {
  pushd "${PASSWORD_STORE_DIR:-$HOME/.password-store}" 1>/dev/null || exit 2
  find . -type f -name '*.gpg' | sed 's/\.gpg//' | sed 's/^\.\///' | sort
  popd 1>/dev/null || exit 2
}

get_password() {
  pass show "${1}" | head -n1
}

main() {
  local -r CURRENT_PANE="$1"
  local selected

  export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=dark
  --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f
  --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
  '

  selected="$(list_passwords | fzf \
    --no-info --no-multi \
    --prompt="󰯄 "  --pointer="󱞪" \
    --header=$'\nCtrl-y=yank, Ctrl-i=inject' \
    --bind=ctrl-i:accept --expect=ctrl-y,ctrl-i)"

  if [ $? -gt 0 ]; then
    tmux display-message "#[fg=red]  Faild To Get Password"
    exit
  fi

  key=$(head -1 <<< "$selected")
  pass=$(tail -n +2 <<< "$selected")

  case $key in
    ctrl-i)
      tmux display-message "#[fg=yellow] 󰶚 Fetching Password..."
      tmux send-keys -t "$CURRENT_PANE" "$(get_password "$pass")"
      tmux display-message "#[fg=green]  Password Inserting Successfully" 
      ;;
    ctrl-y)
      tmux display-message "#[fg=yellow] 󰶚 Fetching Password & Inserting In Clipboard"
      copy_to_clipboard "$(get_password "$pass")"
      clear_from_clipboard 30
      tmux display-message "#[fg=green] 󰢨 Password Now In Clipboard & It Will Remove After 30s"
      ;;
  esac
}

main "$@"
