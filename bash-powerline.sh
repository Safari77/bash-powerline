#!/usr/bin/env bash

## Uncomment to disable git info
#POWERLINE_GIT=0

__powerline() {
    # Colors
    COLOR_RESET='\[\e[m\]'
    COLOR_CWD='\[\e[38;5;110m\]'
    COLOR_GIT='\[\e[38;5;115m\]'
    COLOR_BRACKET='\[\e[38;5;241m\]'
    COLOR_AT='\[\e[38;5;248m\]'
    COLOR_HOST='\[\e[38;5;252m\]'
    COLOR_LUSER='\[\e[38;5;244m\]'
    COLOR_ROOT='\[\e[38;5;215m\]'
    COLOR_SUCCESS='\[\e[38;5;76m\]'
    COLOR_FAILURE='\[\e[38;5;204m\]'

    # Symbols
    SYMBOL_GIT_BRANCH=${SYMBOL_GIT_BRANCH:-⑂}
    SYMBOL_GIT_MODIFIED=${SYMBOL_GIT_MODIFIED:-*}
    SYMBOL_GIT_PUSH=${SYMBOL_GIT_PUSH:-↑}
    SYMBOL_GIT_PULL=${SYMBOL_GIT_PULL:-↓}

    XTERM_TITLE='\[\e]0;\u@\H: \w\a\]'

    if [[ -z "$PS_SYMBOL" ]]; then
      case "$(uname)" in
          Darwin)   PS_SYMBOL='';;
          Linux)    PS_SYMBOL='\$';;
          *)        PS_SYMBOL='%';;
      esac
    fi

    __git_info() { 
        [[ $POWERLINE_GIT = 0 ]] && return # disabled
        hash git 2>/dev/null || return # git not found
        local git_eng="env LANG=C git"   # force git output in English to make our work easier

        # get current branch name
        local ref=$($git_eng symbolic-ref --short HEAD 2>/dev/null)

        if [[ -n "$ref" ]]; then
            # prepend branch symbol
            ref=$SYMBOL_GIT_BRANCH$ref
        else
            # get tag name or short unique hash
            ref=$($git_eng describe --tags --always 2>/dev/null)
        fi

        [[ -n "$ref" ]] || return  # not a git repo

        local marks
        local mod=0

        # scan first two lines of output from `git status`
        while IFS= read -r line; do
            if [[ $line =~ ^## ]]; then # header line
                [[ $line =~ ahead\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PUSH${BASH_REMATCH[1]}"
                [[ $line =~ behind\ ([0-9]+) ]] && marks+=" $SYMBOL_GIT_PULL${BASH_REMATCH[1]}"
            else # branch is modified if output contains more lines after the header line
                mod=1
                break
            fi
        done < <($git_eng status --porcelain --branch -uno --ignored=no --no-renames 2>/dev/null)  # note the space between the two <

        # print the git branch segment without a trailing newline
        if [[ $mod == 1 ]]; then
          printf " $ref$SYMBOL_GIT_MODIFIED$marks"
        else
          printf " $ref$marks"
        fi
    }

    ps1() {
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly. 
        if [[ $? -eq 0 ]]; then
            local symbol=" $COLOR_SUCCESS$PS_SYMBOL$COLOR_RESET"
        else
            local symbol=" $COLOR_FAILURE$PS_SYMBOL$COLOR_RESET"
        fi

        if [[ $UID == 0 ]]; then
            COLOR_USER=$COLOR_ROOT
        else
            COLOR_USER=$COLOR_LUSER
        fi

        local cwd="$COLOR_CWD\w$COLOR_RESET"
        # Bash by default expands the content of PS1 unless promptvars is disabled.
        # We must use another layer of reference to prevent expanding any user
        # provided strings, which would cause security issues.
        # POC: https://github.com/njhartwell/pw3nage
        # Related fix in git-bash: https://github.com/git/git/blob/9d77b0405ce6b471cb5ce3a904368fc25e55643d/contrib/completion/git-prompt.sh#L324
        if shopt -q promptvars; then
            __powerline_git_info="$(__git_info)"
            local git="$COLOR_GIT\${__powerline_git_info}$COLOR_RESET"
        else
            # promptvars is disabled. Avoid creating unnecessary env var.
            local git="$COLOR_GIT$(__git_info)$COLOR_RESET"
        fi

        if [[ -z $SSH_CLIENT ]]; then
            local __ssh=""
        else
            local __ssh="$COLOR_AT@$COLOR_RESET$COLOR_HOST\H$COLOR_RESET"
        fi
        local __user="$COLOR_BRACKET[$COLOR_RESET$COLOR_USER\u$COLOR_RESET$__ssh$COLOR_BRACKET]$COLOR_RESET"
        PS1="$XTERM_TITLE$__user $COLOR_BRACKET+$COLOR_RESET\j $cwd$git$symbol "
        unset __user __ssh
    }

    PROMPT_COMMAND="ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
}

unset PROMPT_COMMAND
__powerline
unset __powerline
