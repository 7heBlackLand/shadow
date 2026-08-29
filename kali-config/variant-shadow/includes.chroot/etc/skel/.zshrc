# ~/.zshrc — Shadow live customization (see Shadow-Shell-Prompt-Design)
#
# Lightweight replacement for Kali's default /etc/skel/.zshrc (kali-defaults):
# only the prompt is themed here. No syntax-highlighting, autosuggestions or
# completion framework is loaded, keeping RAM/CPU/disk usage low on the target
# low-RAM hardware.
#
# Prompt (twoline):
#
#   ┌──(Egypt☯ Shadow)-[~/Desktop]
#   └─$
#
# Colors:
#   - host: first letter red, remainder bold blue
#   - ☯:    bright cyan, followed by a space
#   - user: first letter red, remainder bold blue
#   - ┌── ( ) - [ ] and └─: red (blue if root)
#   - path: bold white, shortened at depth > 5
#   - $ / #: blue $ (red # if root)
#
# Fully dynamic: host and user are capitalized from the real system values via
# print -P %m/%n + the ${(C)...} flag. Ctrl+P toggles between two-line and
# single-line layout.

PROMPT_ALTERNATIVE=twoline

configure_prompt() {
    # Evaluate the real hostname (%m) and username (%n) and capitalize them
    local host user host_name user_name edgec path_prompt prompt_char
    host="$(print -P '%m')"
    user="$(print -P '%n')"
    host="${(C)host}"
    user="${(C)user}"

    # Host and user have the same styling (first letter red, rest bold blue)
    # for root and normal users; only the frame edges and prompt symbol change.
    host_name="%F{red}${host[1]}%f%B%F{blue}${host[2,-1]}%f%b"
    user_name="%F{red}${user[1]}%f%B%F{blue}${user[2,-1]}%f%b"

    if (( EUID == 0 )); then
        edgec="%F{blue}"
        prompt_char="%F{red}#%f"
    else
        edgec="%F{red}"
        prompt_char="%F{blue}$%f"
    fi

    # Path, shortened at depth > 5 (e.g. ~/…/xyz/a/b)
    local parts
    parts=("${(@s:/:)${(%):-%~}}")
    if (( ${#parts} > 5 )); then
        path_prompt="…/${parts[-2]}/${parts[-1]}"
    else
        path_prompt="${(%):-%~}"
    fi

    if [[ "${PROMPT_ALTERNATIVE}" == "twoline" ]]; then
        PROMPT="${edgec}┌──(${host_name}%F{cyan}☯%f ${user_name}${edgec})-${edgec}[%B%F{white}${path_prompt}%f%b${edgec}]%f
${edgec}└─%f ${prompt_char}%f "
        RPROMPT=""
    else
        PROMPT="${edgec}┌──(${host_name}%F{cyan}☯%f ${user_name}${edgec})-${edgec}[%B%F{white}${path_prompt}%f%b${edgec}]%f ${prompt_char}%f "
        RPROMPT=""
    fi
}

# Refresh the prompt before every command so the cwd stays current
precmd_functions=( "${precmd_functions[@]:#configure_prompt}" )
precmd_functions+=(configure_prompt)

# Apply immediately for the first prompt of the session
configure_prompt

# Ctrl+P (Kali-style) toggles between the two-line and single-line layout
toggle_oneline_prompt(){
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi
    configure_prompt
    zle reset-prompt
}
zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt