if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Configure Linuxbrew if it is installed
if test -e /home/linuxbrew/.linuxbrew/bin/brew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if test -d (brew --prefix)"/share/fish/completions"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/.gcloud/path.fish.inc" ];
  . "$HOME/.gcloud/path.fish.inc";
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx PATH $PATH $HOME/.krew/bin

# pnpm
set -gx PNPM_HOME "/Users/tom/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
