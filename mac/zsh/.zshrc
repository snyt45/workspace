eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(zoxide init zsh)"

if [[ $(command -v socat > /dev/null; echo $?) == 0 ]]; then
    # Start up the socat forwarder to clip.exe
    echo "Starting clipboard relay..."
    (socat tcp-listen:8121,fork,bind=0.0.0.0 EXEC:'pbcopy' &) > /dev/null 2>&1
fi

alias g='git'
