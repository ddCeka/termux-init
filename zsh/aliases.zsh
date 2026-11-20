####         ####
#### Aliases ####
####         ####

# Enable color support of ls, diff, grep, dir and bat
if [[ -x "$PREFIX/bin/dircolors" ]]; then
    [[ -r "$HOME/.dircolors" ]] && eval "$(dircolors -b "$HOME/.dircolors")" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias diff='diff --color=auto'
    alias egrep='grep -E --color=auto'
    alias fgrep='fgrep --color=auto'
    alias grep='grep --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto -h'
fi

# Use 'neovim' (if installed)
if [[ -x "$PREFIX/bin/nvim" ]]; then
    alias vi='nvim'
    alias vim='nvim'
fi

# Replace 'cat' with 'bat' (if available)
if [[ -x "$PREFIX/bin/bat" ]]; then
    alias bat='bat --color=always --paging=never'
    alias cat='bat --color=always --decorations=never --paging=never'
fi

# Replace 'ls' with 'eza' (if available) + some aliases
if [[ -x "$PREFIX/bin/eza" ]]; then
    alias l='eza --color=auto --icons=auto'
    alias ls='eza --color=always --group-directories-first --icons=auto'
    alias l.='eza -d --color=auto --icons=auto .*'
    alias la='eza -a --no-user --group-directories-first --color=auto --icons=auto'
    alias ll='eza -ahl --no-user --group-directories-first --classify=always --color=auto --icons=auto'
    alias ll.='eza -hl -d --group-directories-first --classify=always --color=auto --icons=auto .*'
    alias lm='eza --color=auto --icons=auto | less'
    alias l1='eza -1 --group-directories-first --classify=auto --color=auto --icons=auto'
    alias lh='eza -ld --color=auto --icons=auto .??*'
    alias lsn='eza --color=auto --icons=auto | cat -n'
else
    alias l='ls --color=auto'
    alias ls='ls --color=auto'
    alias l.='ls --color=auto -d .*'
    alias la='ls --color=auto -a --group-directories-first'
    alias ll='ls --color=auto -Fhl --classify=always'
    alias ll.='ls --color=auto -Fhl -d .*'
    alias lm='ls --color=auto | less'
    alias l1='ls -1F --color=auto --group-directories-first'
    alias lh='ls -ld --color=auto .??*'
    alias lsn='ls --color=auto | cat -n'
fi

# List all possible commands (Zsh-native replacement for Bash `compgen -c`)
alias allcmd='print -rl -- ${(k)commands} | sort -u | less'

# Common commands
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias .6='cd ../../../../../../'
alias .7='cd ../../../../../../../'
alias .8='cd ../../../../../../../../'
alias cdusr='cd "$PREFIX"'
alias mkdir='mkdir -p -v'
alias rmd='rm -rfv'
alias cpv='cp --preserve=all -v'
alias cpr='cp --preserve=all -R'
alias rsync='rsync -ahW --info=progress2'
alias lincol='printf "lines\ncols\n" | tput -S'
alias preview="fzf --preview='bat --squeeze-blank --color=always --style=full {}' --preview-window=down"
alias q='clear && exit'
alias logout='pkill termux'
alias c='clear'

# Memory
alias df='df -h'
alias free='free -mt'
alias ps='ps -e'
alias ht='htop'

# Backup stuff (matched -J xz flags with .tar.xz filenames)
alias tbkp='tar -cJvf /storage/emulated/0/AppManager/bootstrap/home-backup.tar.xz -C /data/data/com.termux/files ./home'
alias trstr='tar -xJvf /storage/emulated/0/AppManager/bootstrap/home-backup.tar.xz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'
alias etcb='tar -cJvf "$HOME/bootstrap/etcb.tar.xz" -C "$PREFIX/etc" motd termux-login.sh'

# Calendar
alias jan='cal -m January'
alias feb='cal -m February'
alias mar='cal -m March'
alias apr='cal -m April'
alias mei='cal -m May'
alias jun='cal -m June'
alias jul='cal -m July'
alias agu='cal -m August'
alias sep='cal -m September'
alias oct='cal -m October'
alias nov='cal -m November'
alias des='cal -m December'

# Package manager
alias pkguc='pkg update'
alias pkgup='pkg upgrade'
alias pkgli='pkg list-installed'
alias pkgla='pkg list-all'
alias pkgf='pkg info'
alias pkgs='pkg search'
alias pkgsw='pkg show'
alias papc='pkg autoclean && pkg clean'

# Package manager specific
if command -v apt >/dev/null 2>&1; then
    alias pkguc='pkg update && apt list --upgradable -a'
    alias pupg='pkg update && pkg upgrade'
    alias create-pack='termux-create-package'
    alias crepo='termux-change-repo'
    alias listpkgbysize='dpkg-query -Wf '\''${Installed-Size}\t${Package}\n'\'' | sort -n'
elif command -v pacman >/dev/null 2>&1; then
    alias fup='pacman -Syu && pacman -Fy && pacman -Scc'
    alias create-pack='termux-create-package --pacman'
    alias paconf='$EDITOR "$PREFIX/etc/pacman.conf"'
    alias crepo='$EDITOR "$PREFIX/etc/pacman.d/mirrorlist"'
    alias pacupg='pacman -Syu'
    alias pacupd='pacman -Sy'
    alias pacupdb='pacman -Sy && pacman -Fy'
    alias pacin='pacman -S'
    alias pacdl='pacman -Sw'
    alias pacis='pacman -Fy'
    alias pacinu='pacman -U'
    alias pacre='pacman -R'
    alias pacun='pacman -Rcns'
    alias pacinfo='pacman -Qi'
    alias pacview='pacman -Si'
    alias pacse='pacman -Ss'
    alias pacinde='pacman -S --asdeps'
    alias pacclean='pacman -Sc'
    alias pacpurge='pacman -Scc'
    alias listpkgdepend="expac -S '%D'"
    alias listpkgopti="expac -S '%o'"
    alias listpkgbysize="expac -H M '%m\t%n' | sort -h"
    alias listpkgbydate="expac --timefmt='%d-%m-%Y %T' '%l\t%n' | sort -h"
    alias listpkgupdate='expac -S -H M "%k\t%n" $(pacman -Qqu) | sort -sh'
    alias ceklastupd="expac --timefmt='%d-%m-%Y %T' '%l\t%n' | sort | tail -n 20"
    alias listpkgother='comm -23 <(pacman -Qq | sort) <(pacman -Sql main | sort)'
fi

# Custom scripts
alias tcenv='termux-switchenv'
alias tvi='termux-verify-integrity'
alias cek-dep='termux-autodep'
alias reload='termux-reload-settings'
alias perm='termux-setup-storage'
alias tec='termux-elf-cleaner'
alias open='termux-open-url'
alias lock='termux-wake-lock'
alias unlock='termux-wake-unlock'
alias cleaner='termux-junk-cleaner'
alias ccc='create-conventional-changelog'
alias ddl='dead-domains-linter'

# Applications shortcuts
alias tprop='$EDITOR "$HOME/.termux/termux.properties"'
alias cclean='rm -rf "$HOME/.cache" "$HOME/app/logs/cleaner-log.txt"'
alias bclean='rm -rf "$HOME/build" && mkdir -p "$HOME/build"'
alias pclean='killall -9 com.termux.api gpg-agent pulseaudio ssh-agent termux-wake-lock 2>/dev/null'
alias ebashrc='$EDITOR "$HOME/.config/bash/bashrc"'
alias ebashal='$EDITOR "$HOME/.config/bash/aliases.bash"'
alias ebashfu='$EDITOR "$HOME/.config/bash/functions.bash"'
alias ezshrc='$EDITOR "$HOME/.config/zsh/zshrc"'
alias ezshal='$EDITOR "$HOME/.config/zsh/aliases.zsh"'
alias ezshfu='$EDITOR "$HOME/.config/zsh/functions.zsh"'
alias timenow='date +"%R"'
alias datenow='date +"%A, %d %b %m %Y"'
alias untar='tar -xzvf'
alias ctar='tar -czvf'
alias wget='wget -c'
alias e='$EDITOR'
alias sddb='updatedb --database-root /storage/emulated/0/ --output "$HOME/.local/state/locate/sdcard.db"'
alias shck='shellcheck'
alias py2='python2'
alias py='python3'
alias onefetch="onefetch --no-color-palette --no-art --nerd-fonts --no-bold --exclude '**/gradle/libs.versions.toml' --exclude '**/Cargo.lock' --exclude '**/Cargo.toml' --exclude '**/target/**' --exclude '**/CHANGELOG.md' --exclude '**/*.md' --exclude '**/*.txt' --exclude '**/*.json' --exclude '**/node_modules/**' --exclude '**/.github/**' --exclude '**/assets/**' --exclude '**/public/**'"
alias patch-aapt="find ~/.local/gradle -name 'aapt2-*-linux.jar' -type f | xargs -r -I{} jar -uvf {} -C $HOME/.local/bin aapt2"
alias patch-paudio="sed -i 's/module-sles-sink/module-aaudio-sink/g' $PREFIX/etc/pulse/default.pa"
alias apksigned='apksigner sign --ks "$HOME/.keystore/sign.keystore"'
alias zipalcv='zipalign -c -v 4'
alias qalc='qalc -color'
alias localb='git -C "$HOME/build" pull'
alias decolorize='sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g"'
alias wifikey='sudo grep -r "string name=" /data/misc/wifi/WifiConfigStore.xml'

# Git
alias gite='$EDITOR "$HOME/.config/git/gitconfig"'
alias gitel='$EDITOR "$HOME/.config/git/gitconfig.local"'
alias gitei='$EDITOR "$HOME/.config/git/gitignore"'
alias gitab='$EDITOR "$HOME/.config/git/gitattributes"'
alias gital='$EDITOR "$HOME/.config/git/gitconfig.alias"'
alias githem='$EDITOR "$HOME/.config/git/gitconfig.themes"'
alias me='$EDITOR "README.md"'
alias rdm='cat README.md'
alias cglg='cat CHANGELOG.md'
alias lg='lazygit'
alias gfr='git-filter-repo'
alias commit-date="git log -1 --format=%cs | sed 's/-/./g'"
alias commit-sha="find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum"
alias gca="git commit --all -m"
alias gl="git pull --rebase --autostash"
alias gpf="git push --force"
alias gss="git status -s"
alias gsd="git status -s && git diff HEAD"
alias gbrr="git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format='%(refname:short)'"
alias gcm='git checkout $(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed "s@^refs/remotes/origin/@@" || echo main)'
alias gcma="git commit --amend -m"
alias gcman="git commit --amend --no-edit"
alias gcmn="git add . && git commit --amend --no-edit"
alias gdh="git diff HEAD"
alias ghkey='gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$(hostname)" --type signing'
alias ghpr="gh pr create"
alias ghpd="pr_diff"
alias ghpf="pr_files"
alias ghrc="gh repo clone"
alias ghrd="gh repo edit -d"
alias ghrh="gh repo edit -h"
alias ghro="gh repo view --web"
alias ghrr="gh repo rename"
alias ghrs="gh release create"
alias ghrt="gh repo edit --add-topic "
alias ghrv="gh repo edit --accept-visibility-change-consequences --visibility "
alias gmv="git mv"
alias gmx="git merge -X ours"
alias greb="git rebase --interactive --autostash --keep-empty --no-autosquash --rebase-merges main"
alias gsv="git status -v"
alias gtop='cd "$(git rev-parse --show-toplevel)"'
