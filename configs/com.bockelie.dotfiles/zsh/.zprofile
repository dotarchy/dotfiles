# ~/.zprofile — sourced once per login shell, AFTER the text user/pass prompt.
# ===========================================================================
# Auto-launch mlterm-fb as the default terminal on the bare framebuffer console.
#
# HOW THIS IS WIRED (the moving parts you must keep configured):
#
#   1. Package   `mlterm-fb` installed  ->  /usr/bin/mlterm-fb   (AUR: yay -S mlterm-fb)
#
#   2. Wrapper   ~/.local/bin/mlterm-fb  <-  THIS is what we launch, NOT the raw
#                binary. mlterm auto-detects ONE keyboard by /sys name and on a
#                multi-input machine grabs the WRONG evdev node (often the Power
#                Button) -> dead keyboard. The wrapper detects the real keyboard
#                event device(s) and exports KBD_INPUT_NUM.
#                  >> To target different keyboards, edit MLTERM_KBD_MATCH in the
#                     wrapper (a name regex; default "8BitDo").
#                We call it by ABSOLUTE PATH on purpose: ~/.local/bin is not on
#                PATH yet here — it's added later by .zshrc (.zsh/conf.d/00-path),
#                which runs AFTER this file. A bare `mlterm-fb` would hit the raw
#                binary and the keyboard would be dead.
#
#   3. Groups    you must be in BOTH `video` (/dev/fb0) and `input` (/dev/input/*):
#                    sudo gpasswd -a "$USER" video input    # then re-login
#
#   4. Config    ~/.mlterm/{main,aafont,color}   (font / Breeze theme / colors)
#
# LOCKOUT-PROOF BY DESIGN: every guard below must pass or we stay in the plain
# text console; press any key within 2s to skip; and mlterm-fb is *run, not
# exec'd*, so a crash / failed load / normal exit drops you back to this shell,
# never a black screen.
# ===========================================================================

# All auto-launch conditions in one place, each independently commented.
_mlterm_should_launch() {
  [[ "$TERM" == linux && -t 0 ]]          || return 1   # a real VT, interactive
  [[ -z "${DISPLAY}${WAYLAND_DISPLAY}" ]] || return 1   # not inside a graphical session
  [[ -z "${SSH_TTY}${SSH_CONNECTION}" ]]  || return 1   # never over SSH
  [[ -z "${MLTERM}" ]]                    || return 1   # not already inside mlterm (recursion guard)
  [[ -w /dev/fb0 ]]                       || return 1   # framebuffer present + writable (video driver up)
  id -Gn | grep -qw input                 || return 1   # evdev access, else the keyboard is dead
  [[ -x "$HOME/.local/bin/mlterm-fb" ]]   || return 1   # the keyboard-resolving wrapper is installed
}

if _mlterm_should_launch; then
  if read -t 2 -k 1 'k?Starting mlterm-fb — press any key to stay in the plain console… '; then
    print -- $'\nplain console.'
  else
    print
    # NOTE: absolute path to the WRAPPER (sets KBD_INPUT_NUM), not /usr/bin/mlterm-fb.
    "$HOME/.local/bin/mlterm-fb"
    # back here when mlterm-fb exits or crashes; type 'exit' again to log out
  fi
fi
unset -f _mlterm_should_launch
