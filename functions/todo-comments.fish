function todo-comments --description 'Search for (TODO|FIX|FIXME|BUG|PERF|NOTE|IDEA) comments in the current directory using rg'
    # TODO: if --todo is enabled then also search for `todo!()` in rust codebases
    set -l options h/help \
        (fish_opt --short=e --long=extension --multiple-vals) \
        (fish_opt --short=E --long=exclude --multiple-vals) \
        t/todo f/fixme b/bug p/perf n/note v/verbose i/idea \
        F/fzf

    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l reset (set_color normal)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l yellow (set_color yellow)
    set -l blue (set_color blue)
    set -l cyan (set_color cyan)
    set -l magenta (set_color magenta)
    set -l option_color (set_color $fish_color_option)
    set -l bold (set_color --bold)

    set -l editor (command --search nano)
    if set --query EDITOR
        set editor (command --search $EDITOR)
    end

    if set --query _flag_help
        printf "%sSearch for (TODO|FIXME|BUG|PERF|NOTE|IDEA) comments with %srg%s in %s%s%s\n" $bold (set_color $fish_color_command) $reset (set_color --italics --underline) $PWD $reset
        printf "\n"
        printf "%sUSAGE%s: %s%s%s [OPTIONS]\n" $yellow $reset (set_color $fish_color_command) (status function) $reset
        printf "\n"
        printf "%sOPTIONS%s:\n" $yellow $reset
        printf "\t%s-e%s, %s--extension%s=EXTENSION[,EXTENSION...]\tSearch for files with the given extension(s).\n" $option_color $reset $option_color $reset
        printf "\t%s-E%s, %s--exclude%s=EXTENSION[,EXTENSION...]\t\tExclude files with the given extension(s).\n" $option_color $reset $option_color $reset
        printf "\t%s-h%s, %s--help%s\t\t\t\t\tShow this help message and exit.\n" $option_color $reset $option_color $reset
        printf "\t%s-t%s, %s--todo%s\t\t\t\t\tSearch for %sTODO%s comments.\n" $option_color $reset $option_color $reset $yellow $reset
        printf "\t%s-f%s, %s--fixme%s\t\t\t\t\tSearch for %sFIX(ME)?%s comments.\n" $option_color $reset $option_color $reset (set_color brred) $reset
        printf "\t%s-b%s, %s--bug%s\t\t\t\t\tSearch for %sBUG%s comments.\n" $option_color $reset $option_color $reset $red $reset
        printf "\t%s-p%s, %s--perf%s\t\t\t\t\tSearch for %sPERF%s comments.\n" $option_color $reset $option_color $reset $magenta $reset
        printf "\t%s-n%s, %s--note%s\t\t\t\t\tSearch for %sNOTE%s comments.\n" $option_color $reset $option_color $reset $blue $reset
        printf "\t%s-i%s, %s--idea%s\t\t\t\t\tSearch for %sIDEA%s comments.\n" $option_color $reset $option_color $reset $green $reset
        printf "\t%s-v%s, %s--verbose%s\t\t\t\t\tPrint the rg command that will be run.\n" $option_color $reset $option_color $reset
        if command --query fzf
            printf "\t%s-F%s, %s--fzf%s\t\t\t\t\tUse %s%s%s to select the file and line to open with %s%s%s\n" $option_color $reset $option_color $reset (set_color $fish_color_command) (command --search fzf) $reset (set_color $fish_color_command) $editor $reset
        end
        printf "\n"
        printf "%sEXAMPLES%s:\n" $yellow $reset
        printf "\t"
        printf "%s --fixme --bug # Search for lines containing (FIX|FIXME|BUG): in %s" (status function) $PWD | fish_indent --ansi
        printf "\t"
        printf "%s --extension js,ts --todo # Search for lines containing TODO: in *.js and *.ts files in %s" (status function) $PWD | fish_indent --ansi
        printf "\t"
        printf "%s --exclude rs --perf # Search for lines containing PERF: in all files except *.rs files in %s" (status function) $PWD | fish_indent --ansi
        if command --query fzf
            printf "\t"
            printf "%s --fzf --todo # Search for lines containing TODO: in all files in %s and use fzf to select the file and line to open in the editor" (status function) $PWD | fish_indent --ansi
        end

        if not command --query rg
            printf "\n"
            printf "%sERROR%s: rg (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/BurntSushi/ripgrep" $reset
        end

        return 0
    end

    if not command --query rg
        printf "\n"
        printf "%sERROR%s: rg (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/BurntSushi/ripgrep" $reset
        return 1
    end

    if test $PWD = $HOME
        printf "%swarning%s: Not sure it is a good idea to RECURSIVELY search through %s%s%s\n" $yellow $reset (set_color --italics --underline) $PWD $reset
        return 0
    end

    set -l alternatives
    if set --query _flag_todo
        set --append alternatives TODO
    end
    if set --query _flag_fixme
        set --append alternatives FIX FIXME
    end
    if set --query _flag_bug
        set --append alternatives BUG
    end
    if set --query _flag_perf
        set --append alternatives PERF
    end
    if set --query _flag_note
        set --append alternatives NOTE
    end
    if set --query _flag_idea
        set --append alternatives IDEA
    end

    if test (count $alternatives) -eq 0
        # No flags were passed, so use all of them
        set alternatives TODO FIX FIXME BUG PERF NOTE IDEA
    end

    # Enable hyperlinks introduced in rg 0.14.0
    # NOTE: --vimgrep is used to have <file>:<line>:<column>: such that when the hyperlinks is clicked, the file is opened in the editor at the given line and column
    # style oneof {no,}bold {no,}underline {no,}intense
    set -l rg_args \
        --pretty \
        --column \
        --ignore-case \
        --hyperlink-format=default \
        --vimgrep \
        --colors="match:none" \
        --colors="match:bg:yellow" \
        --colors="match:fg:black" \
        --colors="match:style:bold" \
        --colors="path:fg:blue" \
        --colors="line:fg:green" \
        --colors="column:fg:red"

    if set --query _flag_extension
        set -l type extensions
        set --append rg_args --type-add "'$type:*.{$(string join ',' -- $_flag_extension)}'" --type=$type
    end
    if set --query _flag_exclude
        set -l type exclusions
        set --append rg_args --type-add "'$type:*.{$(string join ',' -- $_flag_exclude)}'" --type-not=$type
    end

    set -l regexp (printf '(%s)(\([^)]+\))?:' (string join '|' -- $alternatives))
    set -l rg_command "command rg $rg_args '\\b$regexp'"

    if set --query _flag_verbose
        echo $rg_command | fish_indent --ansi
    end

    if set --query _flag_fzf
        if not command --query fzf
            printf "\n"
            printf "%serror%s: fzf (%s%s%s) is not found in \$PATH\n" $red $reset (set_color --underline) "https://github.com/junegunn/fzf" $reset
            return 1
        end
        # TODO: show some lines above and below the found line
        # TODO: improve colors
        set -l fzf_opts \
            --ansi \
            --exit-0 \
            --delimiter : \
            --nth 3.. \
            --header-first \
            --scroll-off=5 \
            --multi \
            --pointer='|>' \
            --marker='✓ ' \
            --no-mouse \
            --color='marker:#00ff00' \
            --color="header:#$fish_color_command" \
            --color="info:#$fish_color_keyword" \
            --color="prompt:#$fish_color_autosuggestion" \
            --color='border:#F80069' \
            --color="gutter:-1" \
            --color="hl:#FFB600" \
            --color="hl+:#FFB600" \
            --no-scrollbar \
            --cycle \
            --bind "enter:become($EDITOR {1} +{2})" \
            --preview "bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}" \
            --preview-window '~3'
        eval "$rg_command" | fzf $fzf_opts
        set -l pstatus $pipestatus
        if test $pstatus[1] -ne 0
            printf "No matches for regular expression %s'%s'%s in %s%s%s 😎\n" $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
        if test $pstatus[2] -ne 0
            # User most likely pressed `<esc>` in fzf, which will cause it quit and return 1
        end
    else
        eval "$rg_command"
        if test $status -ne 0
            printf "No matches for regular expression %s'%s'%s in %s%s%s 😎\n" $green $regexp $reset (set_color --bold --italics) $PWD $reset
        end
    end
end
