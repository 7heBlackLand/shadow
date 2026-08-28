# ~/.zshrc — Shadow live customization (see terminal-note)
#
# Overrides Kali's configure_prompt() (defined in /etc/zsh/zshrc) to render the
# host-first twoline prompt:
#
#   ┌──(Egypt㉿Shadow)-[~/Desktop]
#   └─$
#
# Colors:
#   - host: blue bold (red if root)
#   - ㉿:   red
#   - user: first letter red, remainder blue bold
#   - ┌── ( ) - [ ]: green (blue if root)
#   - path: bold, shortened at depth > 5
#   - └─: green, $ blue (# red if root)
#
# Fully dynamic: host and user are capitalized from the real values via
# print -P %m/%n + the ${(C)...} flag. Ctrl+P (Kali's PROMPT_ALTERNATIVE
# toggle) keeps working.

configure_prompt() {
    # Evaluate the real hostname (%m) and username (%n) and capitalize them
    local host user host_name user_name edgec path_prompt prompt_char
    host="$(print -P '%m')"
    user="$(print -P '%n')"
    host="${(C)host}"
    user="${(C)user}"

    if (( EUID == 0 )); then
        edgec="%F{blue}"
        host_name="%B%F{red}${host}%f%b"
        prompt_char="%F{red}#%f"
    else
        edgec="%F{green}"
        host_name="%B%F{blue}${host}%f%b"
        prompt_char="%F{blue}$%f"
    fi

    # Username: first letter red, remainder blue bold
    user_name="%F{red}${user[1]}%f%B%F{blue}${user[2,-1]}%f%b"

    # Path, shortened at depth > 5 (e.g. ~/…/xyz/a/b)
    local parts
    parts=("${(@s:/:)${(%):-%~}}")
    if (( ${#parts} > 5 )); then
        path_prompt="…/${parts[-2]}/${parts[-1]}"
    else
        path_prompt="${(%):-%~}"
    fi

    if [[ "${PROMPT_ALTERNATIVE}" == "twoline" ]]; then
        PROMPT="${edgec}┌──(${host_name}%F{red}㉿%f${user_name}${edgec})-${edgec}[%B%F{white}${path_prompt}%f%b${edgec}]%f
${edgec}└─%f ${prompt_char}%f "
        RPROMPT=""
    else
        PROMPT="${edgec}┌──(${host_name}%F{red}㉿%f${user_name}${edgec})-${edgec}[%B%F{white}${path_prompt}%f%b${edgec}]%f ${prompt_char}%f "
        RPROMPT=""
    fi
}

# Refresh the prompt before every command so the cwd stays current
precmd_functions=( "${precmd_functions[@]:#configure_prompt}" )
precmd_functions+=(configure_prompt)

# Apply immediately for the first prompt of the session
configure_prompt