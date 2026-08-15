# if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
#     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
# end

function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set fish_greeting
    # echo
    microfetch
    # echo

    starship init fish | source
    # fzf --fish | source
    zoxide init fish | source

    # alias pamcan pacman
    # alias ls 'eza --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    # alias q 'qs -c ii'
    alias cat bat
    alias catn /bin/cat
    alias catnp 'bat --no-paging'
    alias ll 'lsd -lh --group-dirs=first'
    alias la 'lsd -a --group-dirs=first'
    alias l 'lsd --group-dirs=first'
    alias lla 'lsd -lha --group-dirs=first'
    alias ls 'lsd --group-dirs=first'

    alias gg lazygit
    alias v nvim
    # alias c 'clear -x; echo'
    alias c 'clear -x'
    alias t 'tmux a -t Home || tmux new -s Home'
    alias ff 'fastfetch --config /home/javier/.config/fastfetch/big.jsonc'
    alias ldo lazydocker
    # alias code 'code --use-gl=desktop --ozone-platform-hint="auto" --enable-features="WaylandWindowDecorations" --password-store="gnome-libsecret" --profile "Home"'
    #alias code 'code --ozone-platform-hint="auto" --enable-features="WaylandWindowDecorations" --password-store="gnome-libsecret" --profile "Home"'
    alias code 'code --password-store="gnome-libsecret" --profile "Home"'
    alias cp 'cp -i'
    alias mv 'mv -i'
    alias rm 'trash -v'
    alias mkdir 'mkdir -p'

    # alias to show the date
    alias da 'date "+%Y-%m-%d %A %T %Z"'

    # Change directory aliases
    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias .... 'cd ../../..'
    alias ..... 'cd ../../../..'

    # Remove a directory and all files
    alias rmd 'command rm --recursive --force --verbose '

    # Search files in the current folder
    alias f "find . | grep "

    # Search running processes
    alias p "ps aux | grep "

    # Count all files (recursively) in the current folder
    # alias countfiles "for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

    # Alias's to show disk space and space used in a folder
    alias diskspace "du -S | sort -n -r |more"
    alias folders 'du -h --max-depth=1'
    alias folderssort 'find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
    alias tree 'tree -CAhF --dirsfirst'
    alias treed 'tree -CAFd'
    alias mountedinfo 'df -hT'

    # Alias's for archives
    alias mktar 'tar -cvf'
    alias mkbz2 'tar -cvjf'
    alias mkgz 'tar -cvzf'
    alias untar 'tar -xvf'
    alias unbz2 'tar -xvjf'
    alias ungz 'tar -xvzf'

    alias specials "hyprctl -j workspaces | jq '.[] | select(.name | startswith(\"special\"))'"

    alias nrs "sudo nixos-rebuild switch --flake ~/nixos-config#nixos"
    alias nrt "sudo nixos-rebuild test --flake ~/nixos-config#nixos"
    alias nrb "sudo nixos-rebuild build --flake ~/nixos-config#nixos"

    # function fish_prompt
    #   set_color cyan; echo (pwd)
    #   set_color green; echo '> '
    # end

    function fish_user_key_bindings
        # by `$(brew --prefix)/opt/fzf/install`
        # https://github.com/junegunn/fzf#using-homebrew-or-linuxbrew
        # fzf_key_bindings

        # for accepting autosuggestions in vi mode
        # https://github.com/fish-shell/fish-shell/issues/3541#issuecomment-260001906
        for mode in insert default visual
            bind -M $mode ctrl-f forward-char
            bind -M $mode ctrl-p up-or-search
            bind -M $mode ctrl-n down-or-search
            bind -M $mode ctrl-escape clear-screen
            bind -M $mode ! bind_bang
            bind -M $mode '$' bind_dollar
        end
    end

    function bind_bang
        switch (commandline -t)[-1]
            case "!"
                commandline -t -- $history[1]
                commandline -f repaint
            case "*"
                commandline -i !
        end
    end

    function bind_dollar
        switch (commandline -t)[-1]
            case "!"
                commandline -f backward-delete-char history-token-search-backward
            case "*"
                commandline -i '$'
        end
    end

    function auto_ls --on-variable PWD
        if status --is-interactive
            ls
        end
    end

    fish_vi_key_bindings
    enable_transience
end

set -x XDG_CONFIG_HOME "$HOME/.config"
set -x XDG_DATA_HOME "$HOME/.local/share"
set -x XDG_CACHE_HOME "$HOME/.cache"
set -x XDG_STATE_HOME "$HOME/.local/state"

set -gx BAT_THEME ansi
set -gx EDITOR nvim

# FZF Custom Theming for Fish Shell
set -gx FZF_DEFAULT_OPTS \
    "--color=16" \
    "--color=border:1" \
    "--color=bg+:0" \
    "--bind 'ctrl-y:preview-up,ctrl-e:preview-down'" \
    "--bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up'" \
    "--bind 'alt-p:toggle-preview'"

# set -gx FZF_DEFAULT_OPTS \
#     "--color=fg:-1" \
#     "--color=fg+:-1" \
#     "--color=bg:-1" \
#     "--color=bg+:20" \
#     "--color=pointer:-1" \
#     "--color=header:1" \
#     "--color=border:4" \
#     "--color=hl:16" \
#     "--color=hl+:17" \
#     "--color=info:21" \
#     "--color=prompt:2" \
#     "--color=marker:21" \
#     "--color=spinner:21" \
#     "--color=scrollbar:dim"

set -x CHROME_BIN /usr/bin/chromium

fish_add_path ~/.local/bin

source ~/.config/fish/auto-Hypr.fish
