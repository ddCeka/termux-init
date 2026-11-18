####           ####
#### Functions ####
####           ####

# require onefetch, pkg install onefetch
function check_directory_for_new_repository() {
    local current_repository
    current_repository=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n "$current_repository" && "$current_repository" != "$last_repository" ]]; then
        command -v onefetch >/dev/null 2>&1 && onefetch
    fi
    last_repository="$current_repository"
}

# Enter and show directory summary
function cd() {
    builtin cd "$@" || return
    check_directory_for_new_repository
    if [[ -n "$PS1" ]]; then
        ls -ah --group-directories-first --color=auto
    fi
}

# Count files, links, and directories in current path
function countfiles() {
    local t
    for t in files links directories; do
        printf "%s %s\n" "$(find . -type "${t[1]}" 2>/dev/null | wc -l | tr -d ' ')" "$t"
    done
}

# Count lines, words, and characters in a file
function countlines() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "[✘] Usage: countlines <file>"
        return 1
    elif [[ ! -f "$file" ]]; then
        echo "[✘] File not found"
        return 1
    else
        local lines words chars
        lines=$(wc -l < "$file" | tr -d ' ')
        words=$(wc -w < "$file" | tr -d ' ')
        chars=$(wc -m < "$file" | tr -d ' ')
        printf "Lines : %s\n" "$lines"
        printf "Words : %s\n" "$words"
        printf "Chars : %s\n" "$chars"
    fi
}

# Change directory when multiple folders have the same name (Zsh-compatible)
function cds() {
    if [[ -z "$1" ]]; then
        echo "[✘] Usage: cds <folder-name>"
        return 1
    fi

    local -a matches
    matches=(${(f)"$(find . -type d -name "$1" 2>/dev/null)"})
    local count=${#matches[@]}

    if (( count == 0 )); then
        echo "[i] No directory named '$1' found"
        return 1
    elif (( count == 1 )); then
        cd "${matches[1]}" || return
    else
        echo "[i] Multiple directories found:"
        local i
        for (( i = 1; i <= count; i++ )); do
            echo "$i: ${matches[$i]}"
        done
        local choice
        read -r "choice?Enter number to cd into: "
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            cd "${matches[$choice]}" || return
        else
            echo "[✘] Invalid choice"
            return 1
        fi
    fi
}

# Copy and go to the directory
function cpg() {
    if [[ -d "$2" ]]; then
        cp "$1" "$2" && cd "$2" || return
    else
        cp "$1" "$2"
    fi
}

# Cd into dir and list contents
function cdlc() {
    cd "$1" && ls --color=auto -a --group-directories-first "${2:-.}"
}

# Move and go to the directory
function mvg() {
    if [[ -d "$2" ]]; then
        mv "$1" "$2" && cd "$2" || return
    else
        mv "$1" "$2"
    fi
}

# Create and go to the directory
function mkdirgo() {
    mkdir -p "$1" && cd "$1" || return
}

# Goes up a specified number of directories (e.g., dirup 4)
function dirup() {
    local limit="${1:-1}"
    if [[ ! "$limit" =~ ^[0-9]+$ ]] || (( limit < 1 )); then
        echo "[✘] Usage: dirup <positive_integer>"
        return 1
    fi

    local d=""
    local i
    for (( i = 1; i <= limit; i++ )); do
        d="${d}../"
    done
    cd "${d%/}" || return
}

# Lists all directories matching a name
function listdirs() {
    if [[ -z "$1" ]]; then
        echo "[✘] Usage: listdirs <folder-name>"
        return 1
    fi
    find . -type d -name "$1" -print
}

# Show files which contain a term and open in $EDITOR
function grep_open() {
    local editor="${EDITOR:-nano}"
    rg -l "$1" | fzf --bind "enter:execute($editor {})"
}

# Show disk usage of items in target path
function duf() {
    local target="${1:-.}"
    echo "[i] Disk usage for: $target"
    du -sh "$target"/* 2>/dev/null | sort -hr | head -20
}

# Show disk usage of a directory as a whole (in KB)
function cekdir() {
    local target="${1:-.}"
    echo "[i] Disk usage for: $target"
    du -sk "$target" | cut -f 1
}

# List files owned by a package with size
function ownedpkg() {
    if [[ -z "$1" ]]; then
        echo "[✘] Usage: ownedpkg <package>"
        return 1
    fi

    if command -v apt >/dev/null 2>&1 && [[ -d "$PREFIX/var/lib/dpkg/info" ]]; then
        dpkg -L "$1" 2>/dev/null | xargs -r du -sh 2>/dev/null | sort -h
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Qlq "$1" | grep -v '/$' | sed 's|^|/|' | xargs -r du -sh 2>/dev/null | sort -h
    fi
}

# Interactive package browser
function browsepkg() {
    if command -v apt >/dev/null 2>&1 && [[ -d "$PREFIX/var/lib/dpkg/info" ]]; then
        apt-cache pkgnames | fzf --multi --cycle --layout=reverse \
            --preview "apt-cache show {}" --preview-window=:70% \
            --bind=space:toggle-preview | xargs -ro apt install
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Slq | fzf --multi --cycle --layout=reverse \
            --preview 'pacman -Si {}' --preview-window=:70% \
            --bind='enter:execute(pacman -S {})'
    fi
}

# Download package via aria2 or package manager
function pkgdl() {
    local package="$1"
    if [[ -z "$package" ]]; then
        echo "[✘] Usage: pkgdl <package>"
        return 1
    fi

    echo "[i] Download starting..."
    if command -v apt >/dev/null 2>&1 && [[ -d "$PREFIX/var/lib/dpkg/info" ]]; then
        echo "[i] Downloading with apt..."
        if command -v aria2c >/dev/null 2>&1; then
            apt-get download --print-uris "$package" | awk '{print $1}' | tr -d "'" | aria2c -i -
        else
            apt-get download "$package"
        fi
        echo "[✔] Downloaded $package"
    elif command -v pacman >/dev/null 2>&1; then
        echo "[i] Downloading with pacman..."
        if command -v aria2c >/dev/null 2>&1; then
            pacman -Sp "$package" | aria2c -i -
        else
            pacman -Sw --noconfirm "$package"
        fi
        echo "[✔] Downloaded $package"
    fi
}

# Find largest items in current directory
function flf() {
    du -h -x -s -- * 2>/dev/null | sort -r -h | head -20
}

# Find large files recursively
function findbig() {
    local size="${1:-100M}"
    local path="${2:-.}"
    echo "[i] Finding files larger than $size in $path"
    find "$path" -type f -size "+$size" -exec ls -lh {} + 2>/dev/null | sort -k5 -hr
}

# Searches for text in all files in the current folder
function ftext() {
    if [[ -z "$1" ]]; then
        echo "[✘] Usage: ftext <search_term>"
        return 1
    fi
    grep -iIHrn --color=always "$1" . | less -R
}

# Find and replace text in files (Zsh-compatible)
function freplace() {
    if [[ $# -ne 3 ]]; then
        echo "[✘] Usage: freplace <search_text> <replace_text> <file_glob>"
        echo "[i] Example: freplace 'old_text' 'new_text' '*.txt'"
        return 1
    fi

    local search="$1"
    local replace="$2"
    local pattern="$3"
    local -a files
    files=(${~pattern}(N))

    if (( ${#files[@]} == 0 )); then
        echo "[✘] No files matching '$pattern'"
        return 1
    fi

    echo "[i] Searching for '$search' in files matching '$pattern'"
    echo "[i] Will replace with '$replace'"
    echo "[i] Files that will be modified:"

    local -a matched_files
    matched_files=(${(f)"$(grep -l -- "$search" "${files[@]}" 2>/dev/null)"})

    if (( ${#matched_files[@]} == 0 )); then
        echo "[✘] No files found containing '$search'"
        return 1
    fi

    printf '  %s\n' "${matched_files[@]}"

    local reply
    read -r -k 1 "reply?Continue with replacement? (y/N): "
    echo
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        sed -i.bak "s|${search}|${replace}|g" "${matched_files[@]}"
        echo "[✔] Replacement completed. Original files backed up with .bak extension"
    else
        echo "[i] Operation cancelled"
    fi
}

# Fuzzy find and kill a process
function fkill() {
    local pid tmpfile
    tmpfile=$(mktemp)

    ps -eo user,pid,cmd --sort=-%mem |
        sed 1d |
        fzf --multi \
            --reverse \
            --header=" Select processes to kill (Tab to mark, Enter to kill)" \
            --preview 'ps -p {2} -o pid,user,%cpu,%mem,cmd' \
            --bind 'ctrl-s:toggle-sort' >"$tmpfile"

    if [[ ! -s "$tmpfile" ]]; then
        echo "[✘] No processes selected." >&2
        rm -f "$tmpfile"
        return 1
    fi

    while IFS= read -r line; do
        pid=$(echo "$line" | awk '{print $2}')
        if [[ -n "$pid" ]]; then
            echo "[i] Killing PID $pid…" >&2
            if kill -TERM "$pid" 2>/dev/null; then
                echo "[✔] Sent SIGTERM to $pid" >&2
            else
                echo "[i] SIGTERM failed for $pid, sending SIGKILL…" >&2
                if kill -KILL "$pid" 2>/dev/null; then
                    echo "[✔] Sent SIGKILL to $pid" >&2
                else
                    echo "[✘] Failed to kill $pid" >&2
                fi
            fi
        fi
    done <"$tmpfile"

    rm -f "$tmpfile"
}

# Git workflow helper
function gg() {
    usage(){
        echo "  [i] Usage: gg [options]"
        echo "  "
        echo "  h, help                                 [i] Show this help usage"
        echo "  "
        echo "  --init                             [i] Autoconfigure git options"
        echo "  "
        echo "  a, [add] <files> [--all]                       [i] Add git files"
        echo "  "
        echo "  c, [commit] <text> [--undo]           [i] Create commit messages"
        echo "  "
        echo "  C, [cherry-pick] <commit> <url> [branch]  [i] Cherry pick commit"
        echo "  "
        echo "  b, [branch] feature|hotfix|<name>          [i] Add/Change Branch"
        echo "  "
        echo "  d, [delete] <branch>                           [i] Delete Branch"
        echo "  "
        echo "  l, [log]                                         [i] Display Log"
        echo "  "
        echo "  m, [merge] feature|hotfix|<name> <message>|<version>   [i] Merge"
        echo "  "
        echo "  p, [push] <branch>                                [i] Push files"
        echo "  "
        echo "  P, [pull] <branch> [--force]                      [i] Pull files"
        echo "  "
        echo "  r, [release] <version>        [i] Merge develop branch on master"
        echo "  "
        echo "  s, [submodule]               [i] Update all submodules on branch"
        return 1
    }

    case "$1" in
        --init)
            local NAME EMAIL USER EDITOR_CFG
            NAME=$(git config --global user.name)
            EMAIL=$(git config --global user.email)
            USER=$(git config --global github.user)
            EDITOR_CFG=$(git config --global core.editor)

            [[ -z "$NAME" ]] && read -r "NAME?Name: "
            [[ -z "$EMAIL" ]] && read -r "EMAIL?Email: "
            [[ -z "$USER" ]] && read -r "USER?Username: "
            [[ -z "$EDITOR_CFG" ]] && read -r "EDITOR_CFG?Editor: "

            git config --global user.name "$NAME"
            git config --global user.email "$EMAIL"
            git config --global github.user "$USER"
            git config --global color.ui true
            git config --global color.status auto
            git config --global color.branch auto
            git config --global color.diff auto
            git config --global diff.color true
            git config --global core.filemode true
            git config --global push.default current
            git config --global core.editor "$EDITOR_CFG"
            git config --global format.signoff true
            git config --global alias.reset 'reset --soft HEAD^'
            git config --global alias.graph 'log --graph --oneline --decorate'
            git config --global alias.compare 'difftool --dir-diff HEAD^ HEAD'

            if command -v vimdiff >/dev/null 2>&1; then
                git config --global diff.guitool vimdiff
                git config --global merge.tool vimdiff
            elif command -v meld >/dev/null 2>&1; then
                git config --global diff.guitool meld
                git config --global merge.tool meld
            elif command -v kdiff3 >/dev/null 2>&1; then
                git config --global diff.guitool kdiff3
                git config --global merge.tool kdiff3
            fi
            git config --global --list
            ;;
        a | add)
            if [[ "$2" == "--all" ]]; then
                git add -A
            else
                shift
                git add "$@"
            fi
            ;;
        b | branch)
            local check_branch check_dev_branch
            case "$2" in
                feature)
                    check_dev_branch=$(git branch --list dev)
                    if [[ -z "$check_dev_branch" ]]; then
                        echo "[i] creating develop branch..."
                        git branch dev
                        git push -u origin dev
                    fi
                    git checkout -b feature --track origin/dev
                    ;;
                hotfix)
                    git checkout -b hotfix master
                    ;;
                master)
                    git checkout master
                    ;;
                *)
                    check_branch=$(git branch --list "$2")
                    if [[ -z "$check_branch" ]]; then
                        echo "[i] creating $2 branch..."
                        git branch "$2"
                        git push -u origin "$2"
                    fi
                    git checkout "$2"
                    ;;
            esac
            ;;
        c | commit)
            if [[ "$2" == "--undo" ]]; then
                git reset --soft HEAD^
            else
                git commit -am "$2"
            fi
            ;;
        C | cherry-pick)
            local commit_hash="$2"
            local remote_url="$3"
            local remote_branch="${4:-main}"
            if [[ -z "$commit_hash" || -z "$remote_url" ]]; then
                echo "[✘] Usage: gg cherry-pick <commit> <url> [branch]"
                return 1
            fi
            git checkout -b patch master
            git pull "$remote_url" "$remote_branch"
            git checkout master
            git cherry-pick "$commit_hash"
            git log -n 5
            git branch -D patch
            ;;
        d | delete)
            local check_branch
            check_branch=$(git branch --list "$2")
            if [[ -z "$check_branch" ]]; then
                echo "[✘] no branch found."
                return 1
            else
                git branch -D "$2"
                git push origin --delete "$2"
            fi
            ;;
        l | log)
            git log --oneline --decorate -n 10
            ;;
        m | merge)
            local check_branch
            check_branch=$(git branch --list "$2")
            case "$2" in
                --fix)
                    git mergetool --no-gui
                    ;;
                feature)
                    if [[ -n "$check_branch" ]]; then
                        git checkout dev
                        git difftool --no-gui -d dev..feature
                        git merge --no-ff feature -m "${3:-Merge feature}"
                        git branch -d feature
                    else
                        echo "[✘] no feature branch found."
                        return 1
                    fi
                    ;;
                hotfix)
                    if [[ -n "$check_branch" ]]; then
                        git checkout dev
                        git merge --no-ff hotfix -m "hotfix: v${3}"
                        git checkout master
                        git merge --no-ff hotfix -m "hotfix: v${3}"
                        git branch -d hotfix
                        git tag -a "$3" -m "release: v${3}"
                        git push --tags
                    else
                        echo "[✘] no hotfix branch found."
                        return 1
                    fi
                    ;;
                *)
                    if [[ -n "$check_branch" ]]; then
                        git checkout master
                        git difftool --no-gui -d "master..$2"
                        git merge --no-ff "$2" -m "${3:-Merge $2}"
                        git branch -d "$2"
                    else
                        echo "[✘] branch '$2' not found."
                        return 1
                    fi
                    ;;
            esac
            ;;
        p | push)
            git push origin "$2"
            ;;
        P | pull)
            if [[ "$2" == "--force" ]]; then
                git fetch --all
                git reset --hard origin/master
            else
                git pull origin "$2"
            fi
            ;;
        r | release)
            if [[ -z "$2" ]]; then
                echo "[✘] Usage: gg release <version>"
                return 1
            fi
            git checkout master
            git merge --no-ff dev -m "release: v${2}"
            git tag -a "$2" -m "release: v${2}"
            git push --tags
            ;;
        s | submodule)
            git submodule foreach git pull origin master
            ;;
        * | h | help)
            usage
            ;;
    esac
}

# Clean merged git branches
function ciaclean() {
    local branch="$1"
    if [[ -z "$branch" ]]; then
        echo "[✘] Usage: ciaclean <master|main>"
        return 1
    fi

    echo "[i] Cleaning merged git branches into $branch"
    git branch --merged "origin/${branch}" \
        | grep -vE "^\s*(\*|${branch}|dev)" \
        | xargs -r -n 1 git branch -d
}

# Update last N commits date to now
function git_now() {
    if [[ $# -ne 1 ]] || [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "[✘] Usage: git_now <number_of_commits>"
        echo "[i] Example: git_now 4"
        return 1
    fi
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter \
        'export GIT_AUTHOR_DATE="$(date)" GIT_COMMITTER_DATE="$(date)"' \
        "HEAD~${1}..HEAD"
}

# Clone repo and auto-sync submodules if present
function gcs() {
    if [[ $# -ne 1 ]]; then
        echo "[✘] Usage: gcs <repo-url>"
        echo "[i] Example: gcs https://github.com/user/repo.git"
        return 1
    fi
    git clone "$1" || return 1
    local repo_dir
    repo_dir=$(basename "$1" .git)
    if [[ -f "$repo_dir/.gitmodules" ]]; then
        git -C "$repo_dir" submodule update --init --recursive
    fi
}

# Review changed files on current branch against base branch
function review_changes() {
    local base_branch="${1:-}"
    local editor="${EDITOR:-nvim}"

    if [[ -z "$base_branch" ]]; then
        base_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
        [[ -z "$base_branch" ]] && base_branch="main"
    fi

    git diff --name-only "$base_branch"...HEAD | fzf \
        --preview "git diff $base_branch...HEAD -- {} | delta --width \$FZF_PREVIEW_COLUMNS" \
        --bind "enter:execute($editor {})"
}

# Show staged and unstaged file changes
function changed_files() {
    local editor="${EDITOR:-nvim}"
    git status --short | awk '{print $2}' | fzf \
        --preview "git diff --cached -- {} | delta --width \$FZF_PREVIEW_COLUMNS && git diff -- {} | delta --width \$FZF_PREVIEW_COLUMNS" \
        --bind "enter:execute($editor {})"
}

# Show diff for argument PR number for current repo
function pr_diff() {
    if command -v gh >/dev/null 2>&1; then
        gh pr diff "$1" | delta
    else
        echo "[✘] Command not found. Install github-cli first"
        return 1
    fi
}

# Show PR files for argument PR number for current repo
function pr_files() {
    local editor="${EDITOR:-nvim}"
    if command -v gh >/dev/null 2>&1; then
        gh pr diff "$1" --name-only | fzf \
            --bind "enter:execute($editor {})"
    else
        echo "[✘] Command not found. Install github-cli first"
        return 1
    fi
}

# Quick file encryption with openssl
function encrypt() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "[✘] Usage: encrypt <file>"
        return 1
    fi

    echo "[i] Encrypting $file"
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$file" -out "${file}.enc" &&
        echo "[✔] Encrypted to ${file}.enc"
}

# Quick file decryption with openssl
function decrypt() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "[✘] Usage: decrypt <encrypted_file>"
        return 1
    fi

    local output="${file%.enc}"
    echo "[i] Decrypting $file"
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$file" -out "$output" &&
        echo "[✔] Decrypted to $output"
}

# Calculate file checksums
function checksum() {
    local file="$1"
    if [[ -z "$file" || ! -f "$file" ]]; then
        echo "[✘] Usage: checksum <file>"
        return 1
    fi

    echo "[i] Checksums for: $file"
    echo "  MD5:    $(md5sum "$file" | cut -d' ' -f1)"
    echo "  SHA1:   $(sha1sum "$file" | cut -d' ' -f1)"
    echo "  SHA256: $(sha256sum "$file" | cut -d' ' -f1)"
}

# Convert between different bases (hex, decimal, binary, octal)
function convbase() {
    if [[ $# -ne 2 ]]; then
        echo "[✘] Usage: convbase <from_base> <number>"
        echo "[i] Bases: bin, oct, dec, hex"
        echo "[i] Example: convbase hex ff"
        return 1
    fi

    local from_base="$1"
    local number="$2"
    local decimal

    echo "[i] Converting $number from $from_base:"

    case "$from_base" in
        bin | binary)      decimal=$((2#$number)) ;;
        oct | octal)       decimal=$((8#$number)) ;;
        dec | decimal)     decimal="$number" ;;
        hex | hexadecimal) decimal=$((16#$number)) ;;
        *)
            echo "[✘] Unsupported base: $from_base"
            return 1
            ;;
    esac

    printf "  Decimal:     %d\n" "$decimal"
    printf "  Hexadecimal: %x\n" "$decimal"
    printf "  Octal:       %o\n" "$decimal"
    printf "  Binary:      %s\n" "$(echo "obase=2; $decimal" | bc)"
}

# Rename filenames to lowercase
function lwrcase() {
    if (( $# == 0 )); then
        echo "[✘] Usage: lwrcase <file1> [file2 ...]"
        return 1
    fi

    local file filename dirname nf newname
    for file in "$@"; do
        filename=${file##*/}
        case "$filename" in
            */*) dirname=${file%/*} ;;
            *)   dirname=. ;;
        esac
        nf=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        newname="${dirname}/${nf}"
        if [[ "$nf" != "$filename" ]]; then
            mv -- "$file" "$newname"
            echo "[i] Lowercase: $file --> $newname"
        else
            echo "[i] Lowercase: $file already lowercase."
        fi
    done
}

# Quick HTTP server in current directory
function phttp() {
    local port="${1:-8000}"
    echo "[i] Starting HTTP server on port $port"
    echo "[i] Serving files from: $(pwd)"
    echo "[i] Access at: http://localhost:$port"
    echo "[i] Press Ctrl+C to stop"

    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port"
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port"
    else
        echo "[✘] Python not found. Cannot start HTTP server"
        return 1
    fi
}

# Show listening ports
function ports() {
    echo "[i] Listening ports and processes:"
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep LISTEN
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep LISTEN
    else
        echo "[✘] Neither ss nor netstat found"
        return 1
    fi
}

# Generate random password
function genpass() {
    local length="${1:-16}"
    echo "[i] Generating password of length $length"

    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 $((length * 2)) | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$length"
    elif [[ -e /dev/urandom ]]; then
        tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length"
    else
        echo "[✘] Cannot generate password: no suitable random source found"
        return 1
    fi
    echo
}

# Quick backup of a file or directory
function qbackup() {
    local item="$1"
    if [[ -z "$item" ]]; then
        echo "[✘] Usage: qbackup <file_or_directory>"
        return 1
    fi

    local backup_name
    backup_name="${item}.backup.$(date +%d%m%Y-%H%M)"
    echo "[i] Creating backup: $backup_name"

    if [[ -d "$item" ]]; then
        cp -rv "$item" "$backup_name"
    else
        cp -v "$item" "$backup_name"
    fi

    echo "[✔] Backup created: $backup_name"
}

# Execute command in directory
function execin() {
    (cd "${1}" && shift && "${@}")
}

# Kill all detached tmux sessions
function tmux_clean() {
    tmux list-sessions 2>/dev/null | grep -E -v '\(attached\)$' | while IFS= read -r line; do
        tmux kill-session -t "${line%%:*}"
    done
}

# Edit a binary/script in $PATH
function bined() {
    local editor="${EDITOR:-nvim}"
    local bin
    bin=$(command -v "$1")
    if [[ -z "$bin" ]]; then
        echo "[✘] Binary not found in path"
        return 1
    fi
    "$editor" "$bin"
}

# Runs when tab is pressed after ** in fzf completion
function fzf_comprun() {
    local command="$1"
    shift

    case "$command" in
        cd) fzf "$@" --preview 'ls -TFl --group-directories-first --icons --git -L 2 --no-user {}' ;;
        *)  fzf "$@" ;;
    esac
}

# Extract any archive(s)
function ex() {
    local archive="$1"

    if [[ -z "$archive" || ! -f "$archive" ]]; then
        echo "[✘] '${archive:-<empty>}' doesn't exist"
        return 1
    fi

    echo "[i] Archive: $archive"
    echo "[i] Size: $(du -h "$archive" | cut -f1)"
    echo "[i] Type: $(file -b "$archive")"
    echo

    local archive_dir archive_name current_dir
    archive_dir=$(dirname "$(realpath "$archive")")
    archive_name=$(basename "$archive")
    current_dir=$(pwd)

    if [[ "$current_dir" != "$archive_dir" ]]; then
        cd "$archive_dir" || return 1
        echo "[i] Changed to directory: $archive_dir"
    fi

    local temp_before
    temp_before=$(mktemp)
    ls -1A "$archive_dir" 2>/dev/null | sort >"$temp_before"

    case "$archive" in
        *.tar.gz | *.tgz)               tar -xzvf "$archive_name" ;;
        *.tar.xz | *.txz)               tar -xJvf "$archive_name" ;;
        *.tar.bz2 | *.tbz2 | *.tbz)     tar -xjvf "$archive_name" ;;
        *.tar.Z | *.tZ)                 tar -xZvf "$archive_name" ;;
        *.tar.lz | *.tlz)               tar --lzip -xvf "$archive_name" ;;
        *.tar.lzma)                     tar --lzma -xvf "$archive_name" ;;
        *.tar.lzo)                      tar --lzop -xvf "$archive_name" ;;
        *.tar.zst | *.tzst)             tar --zstd -xvf "$archive_name" ;;
        *.tar)                          tar -xvf "$archive_name" ;;
        *.bz2)                          bunzip2 -v "$archive_name" ;;
        *.gz)                           gunzip -v "$archive_name" ;;
        *.xz)                           unxz -v "$archive_name" ;;
        *.lzma)                         unlzma -v "$archive_name" ;;
        *.Z)                            uncompress -v "$archive_name" ;;
        *.lz)                           lzip -dv "$archive_name" ;;
        *.lzo)                          lzop -dv "$archive_name" ;;
        *.zst)                          zstd -dv "$archive_name" ;;
        *.7z)                           7zz x "$archive_name" ;;
        *.zip | *.jar | *.war | *.ear | *.apk) unzip "$archive_name" ;;
        *.rar)                          unrar x "$archive_name" ;;
        *.ace)                          unace x "$archive_name" ;;
        *.arj)                          arj e "$archive_name" ;;
        *.cab)                          cabextract "$archive_name" ;;
        *.lha | *.lzh)                  lha x "$archive_name" ;;
        *.rpm)                          rpm2cpio "$archive_name" | cpio -idmv ;;
        *.deb)                          ar x "$archive_name" ;;
        *.iso)
            local extract_dir="${archive_dir}/${archive_name%.iso}_extracted"
            mkdir -p "$extract_dir"
            if command -v 7zz >/dev/null 2>&1; then
                7zz x "$archive" -o"$extract_dir"
            else
                echo "[✘] 7zz is required to extract ISO images without root"
                rm -f "$temp_before"
                return 1
            fi
            ;;
        *.cpio)                         cpio -idmv <"$archive_name" ;;
        *.shar)                         sh "$archive_name" ;;
        *.a)                            ar x "$archive_name" ;;
        *.rpa)                          unrpa "$archive_name" && rm -f "$archive_name" ;;
        *)                              7zz x "$archive_name" ;;
    esac

    local status_code=$?
    if (( status_code != 0 )); then
        echo "[✘] Failed to extract $archive"
        rm -f "$temp_before"
        return 1
    fi

    echo
    echo "[✔] Successfully extracted $archive"

    local temp_after newly_added
    temp_after=$(mktemp)
    ls -1A "$archive_dir" 2>/dev/null | sort >"$temp_after"
    newly_added=$(comm -13 "$temp_before" "$temp_after")

    if [[ -n "$newly_added" ]]; then
        echo "[i] Extracted files:"
        while IFS= read -r file; do
            [[ -n "$file" ]] && echo "    $file"
        done <<<"$newly_added"
    else
        echo "[i] No new top-level files found (extracted into existing subdirectories)"
    fi

    rm -f "$temp_before" "$temp_after" 2>/dev/null
}

# File(s) compressor
function compact() {
    if (( $# >= 2 )); then
        local file="$1"
        shift
        case "$file" in
            *.[tT][aA][rR].[bB][zZ]*|*.[tT][bB][zZ]*)                   tar jcvf "$file" "$@" ;;
            *.[tT][aA][rR].[gG][zZ]|*.[tT][gG][zZ]|*.[gG][tT][gG][zZ]) tar czvf "$file" "$@" ;;
            *.[tT][aA][rR].[xX][zZ]|*.[tT][xX][zZ])                   tar cJvf "$file" "$@" ;;
            *.[tT][aA][rR])                                            tar cvf "$file" "$@" ;;
            *.[bB][zZ]2)                                               bzip2 -z -k "$@" ;;
            *.[rR][aA][rR])                                            rar a -r "$file" "$@" ;;
            *.[gG][zZ])                                                gzip -r "$@" ;;
            *.[zZ][iI][pP])                                            zip -r "$file" "$@" ;;
            *.7[zZ])                                                   7zz a -r "$file" "$@" ;;
            *.[xX][zZ])                                                xz -z -k "$@" ;;
            *) echo "[✘] Don't know how to compress '$file' ..." ; return 1 ;;
        esac
    else
        echo "[i] Usage: compact <filename.extension> ./dir(s) ./file(s)"
        return 1
    fi
}

# Updates all package managers installed, lists updated packages, counts, and disk usage
function uall() {
    echo "[i] Starting update-all..."
    local initial_usage
    initial_usage=$(df -h ~ | awk 'NR==2 {print $3}')
    echo "[i] Initial storage used: $initial_usage"

    local grand_total=0
    local -a managers=()
    command -v apt >/dev/null 2>&1 && [[ -d "$PREFIX/var/lib/dpkg/info" ]] && managers+=("apt")
    command -v pacman >/dev/null 2>&1 && [[ -d "$PREFIX/var/lib/pacman/local" ]] && managers+=("pacman")
    command -v pip >/dev/null 2>&1 && managers+=("pip")

    local mgr updated_list count
    for mgr in "${managers[@]}"; do
        echo
        echo "[i] Updating with $mgr..."
        updated_list=""
        count=0

        case "$mgr" in
            apt)
                apt update -y >/dev/null 2>&1
                updated_list=$(apt list --upgradable 2>/dev/null | grep -v "^Listing\.\.\." || true)
                if [[ -n "$updated_list" ]]; then
                    apt upgrade -y >/dev/null 2>&1
                    count=$(printf '%s\n' "$updated_list" | wc -l | tr -d ' ')
                fi
                ;;
            pacman)
                pacman -Sy >/dev/null 2>&1
                updated_list=$(pacman -Qu 2>/dev/null || true)
                if [[ -n "$updated_list" ]]; then
                    pacman -Syu --noconfirm >/dev/null 2>&1
                    count=$(printf '%s\n' "$updated_list" | wc -l | tr -d ' ')
                fi
                ;;
            pip)
                local outdated pkgname
                outdated=$(pip list --outdated --format=freeze 2>/dev/null | cut -d '=' -f1 || true)
                for pkgname in ${(f)outdated}; do
                    [[ -z "$pkgname" ]] && continue
                    pip install --upgrade "$pkgname" >/dev/null 2>&1
                    updated_list+="$pkgname"$'\n'
                    ((count++))
                done
                ;;
        esac

        echo "[i] Updated packages for $mgr:"
        if [[ -n "$updated_list" ]]; then
            printf '%s\n' "$updated_list"
        else
            echo "  (none)"
        fi
        echo "[i] Total updates for $mgr: $count"
        grand_total=$((grand_total + count))
    done

    local final_usage
    final_usage=$(df -h ~ | awk 'NR==2 {print $3}')
    echo
    echo "[i] Grand total of updated packages: $grand_total"
    echo "[i] Storage used before: $initial_usage"
    echo "[i] Storage used after : $final_usage"
}

# Quick note taking
function note() {
    local note_file="$HOME/doc/notes/note.md"
    mkdir -p "$(dirname "$note_file")"
    if (( $# == 0 )); then
        echo "[i] Current notes:"
        cat "$note_file" 2>/dev/null || echo "[i] No notes found"
    else
        echo "$(date '+%d-%m-%Y %H:%M:%S'): $*" >>"$note_file"
        echo "[✔] Note added"
    fi
}
