#!/usr/bin/env zsh

# Exit codes
[[ -z "$AUTOPROJECT_RESET_EXIT_CODE" ]] && AUTOPROJECT_RESET_EXIT_CODE=101;
[[ -z "$AUTOPROJECT_DIR_CHANGE_EXIT_CODE" ]] && AUTOPROJECT_DIR_CHANGE_EXIT_CODE=102;

# Config paths
[[ -z "$AUTOPROJECT_CONFIGS_DIR" ]] && AUTOPROJECT_CONFIGS_DIR="$XDG_CONFIG_HOME/autoproject";
[[ -z "$AUTOPROJECT_DATA_DIR" ]] && AUTOPROJECT_DATA_DIR="$XDG_DATA_HOME/autoproject";
[[ -z "$AUTOPROJECT_STATE_DIR" ]] && AUTOPROJECT_STATE_DIR="$XDG_STATE_HOME/autoproject";
mkdir -p "$AUTOPROJECT_CONFIGS_DIR";
mkdir -p "$AUTOPROJECT_DATA_DIR";
mkdir -p "$AUTOPROJECT_STATE_DIR";
mkdir -p "$AUTOPROJECT_DATA_DIR/allowed";

autoproject::find_projectrc() {
    # Traverses parents and finds the first .project file or the first
    local dir="$PWD";
    while [ "$dir" != "/" ]; do
        if [[ -f "$dir/.projectrc" ]]; then
            echo "$dir/.projectrc";
            break;
        fi
        dir="$(dirname $dir)";
    done;
}

autoproject::get_project_id() {
    local projectrc=$(autoproject::find_projectrc);
    if [[ -n "$projectrc" ]]; then
        readlink -f $projectrc | md5sum | awk '{print $1}';
        return 0;
    fi
    return 1;
}

autoproject::check_projectrc_allowed() {
    local project_id="$(autoproject::get_project_id)";
    local projectrc=$(autoproject::find_projectrc);

    [[ -z "$project_id" || -z "$projectrc" ]] && return;

    local allowed_file="$AUTOPROJECT_DATA_DIR/allowed/$project_id";
    [[ -f $allowed_file ]] || touch $allowed_file;
    if ! md5sum -c $allowed_file &> /dev/null; then
        echo -n "The .projectrc file has changed. Reload shell? [y/N]: ";
        read reload;
        if [[ "${reload:l}" =~ ^[y](es)?$ ]]; then
            md5sum $projectrc > $allowed_file;
            # Exit the current subshell with the special exit code
            # This will trigger a reload in the parent shell
            autoproject::reload;
        else
            # Update the allowed file to prevent future prompts for the same file
            md5sum $projectrc > $allowed_file;
        fi
    fi
}


# This is run on precmd()
autoproject::init() {
    autoproject::check_projectrc_allowed;
    local found_projectrc="$(autoproject::find_projectrc)";

    if [[ -n "$found_projectrc" && -z "$PROJECTRC" ]]; then
        export PROJECTRC="$found_projectrc";
    fi

    # If we can identify the project_id, and PROJECT_ID is not yet set in env,
    # we're ready to enter the subshell.
    local found_project_id="$(autoproject::get_project_id)";
    if [[ -n "$found_project_id" && -z "$PROJECT_ID" ]]; then
        export PROJECT_ID="$found_project_id";

        # Enter subshell
        zsh -i;

        # Subshell has exited
        local exit_code="$?";
        local project_id="$PROJECT_ID";
        unset PROJECTRC;
        unset PROJECT_ID;

        local exitdir_file="$AUTOPROJECT_STATE_DIR/$project_id.exitdir";
        if [[ -f "$exitdir_file" ]]; then
            # force-enter directory from exitdir_file
            cd "$(cat $exitdir_file)";
            rm "$exitdir_file";
        fi

        # Check exit code and handle accordingly
        if [[ "$exit_code" == "$AUTOPROJECT_RESET_EXIT_CODE" ]]; then
            # If we have come from a reset, re-enter the directory
            # On the next prompt, it should trigger init in the directory
            autoproject::init;
        elif [[ "$exit_code" != "$AUTOPROJECT_DIR_CHANGE_EXIT_CODE" ]]; then
            # On normal exit, just `exit`.
            exit $exit_code;
        fi
    elif [[ -n "$PROJECTRC" && -z "$PROJECT_DIR" ]]; then
        export PROJECT_DIR="$(dirname $PROJECTRC)";
        export PROJECT="$(basename $PROJECT_DIR)";
        function use() {
            source "$AUTOPROJECT_CONFIGS_DIR/$1";
        }
        autoproject_on_exit=()
        for lib in ${AUTOPROJECT_DEFAULTS[@]}; do
            source "$AUTOPROJECT_CONFIGS_DIR/$lib";
        done
        source "$PROJECTRC";
    elif [[ -n "$PROJECT_DIR" && $PWD/ != $PROJECT_DIR/* ]]; then
        # We have left the project directory, exit the subshell
        autoproject::reload "$AUTOPROJECT_DIR_CHANGE_EXIT_CODE";
    fi
}

autoproject::reload() {
    [[ -z "$PROJECT_ID" ]] && return;
    [[ -n "$1" ]] && exit_code="$1" || exit_code="$AUTOPROJECT_RESET_EXIT_CODE";
    echo $PWD > "$AUTOPROJECT_STATE_DIR/$PROJECT_ID.exitdir";
    exit "$exit_code";
}

autoproject::on_exit() {
    [[ -z "$PROJECT_DIR" ]] && return;
    for exit_func in "${autoproject_on_exit[@]}"; do
        $exit_func
    done
    fc -W  # writes history to the HISTFILE
}

trap autoproject::on_exit EXIT
