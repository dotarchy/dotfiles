# ~/.zshrc — loader. All config lives in ~/.zsh/conf.d/ and runs in filename order.
#
# Interactive-only: zsh skips this file for non-interactive shells. Anything every
# shell needs (PATH, GOPATH) belongs in ~/.zshenv instead — see the note there.
#
#   04-host          per-host overlay (sources ~/.zsh/host.d/$HOST/*)
#   05-local-pre     sources ~/.zshrc.local (theme, SSH keys, machine extras)
#   10-history       HISTFILE, HISTSIZE, HIST_* options
#   20-options       general setopt flags and WORDCHARS
#   30-completion    zstyles + compinit (once, with daily cache)
#   40-plugins       zsh-autosuggestions, syntax-highlighting, history-substring-search
#   50-keybindings   all bindkey lines
#   60-prompt        oh-my-posh (falls back to prompt elite2)
#   70-aliases       normal aliases (not alias -g) + lsd_with_hint
#   80-ssh-agent     keychain for SSH keys
#   90-tools         direnv, git color default
#   95-auto-update   background `dotfiles pull && deploy` if host opts in

ZSH_CONFD="$HOME/.zsh/conf.d"
if [[ -d "$ZSH_CONFD" ]]; then
  for _f in "$ZSH_CONFD"/*(.N); do
    [[ -r "$_f" ]] && source "$_f"
  done
  unset _f
fi
unset ZSH_CONFD
