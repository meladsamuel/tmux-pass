#!/usr/bin/env bash

command_found() {
	command -v "$1" &>/dev/null
	return $?
}

authenticate_user() {
	# Only authenticate on macOS
	if [[ "$(uname)" != "Darwin" ]]; then
		return 0  # Skip on non-macOS
	fi

	# Check if already authenticated (cached sudo credentials)
	if sudo -n true 2>/dev/null; then
		echo "✓ Authenticated"
		sleep 0.5
		clear
		return 0
	fi

	# Display authentication prompt
	clear
	echo ""
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo "  🔐 tmux-pass Authentication"
	echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	echo ""
	echo "Touch ID or enter your password"
	echo ""

	# Attempt authentication (triggers Touch ID or password prompt)
	if sudo -v 2>/dev/null; then
		clear
		echo "✓ Authentication successful"
		sleep 0.5
		clear
		return 0
	else
		clear
		echo ""
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo "  ❌ Authentication Failed"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo ""
		sleep 2
		return 1
	fi
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

	# Authenticate user before showing password list
	if ! authenticate_user; then
		exit 1
	fi

	selected="$(list_passwords | fzf \
		--no-info --no-multi --border \
		--prompt=" 󰯄 " --pointer="󱞪" \
		--header=$'\nCtrl-y=yank, Ctrl-i=inject' \
		--bind=ctrl-i:accept --expect=ctrl-y,ctrl-i)"

	if [ $? -gt 0 ]; then
		tmux display-message "#[fg=red]  Faild To Get Password"
		exit
	fi

	key=$(head -1 <<<"$selected")
	pass=$(tail -n +2 <<<"$selected")

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
