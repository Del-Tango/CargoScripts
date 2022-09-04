#!/bin/bash
#
# Excellent Regards, the Alveare Solutions #!/Society -x
#
declare -A SYS_CMD
declare -a DOX_FILE_PATHS

# Text Colors

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
RESET=`tput sgr0`

SCRIPT_NAME="${CYAN}(${BLUE}DOX${CYAN})Reader${RESET}"
VERSION='TrustMeImADoctor'
VERSION_NO='1.0'

# HOT PARAMETERS

ROOT_DIR_PATH="$1"

# COLD PARAMETERS

DOX_FILE_PATHS=()
SYS_CMD=(
['dox-scan']="find \$ROOT_DIR_PATH -type f -name '*.dox'"
)

function fetch_dox_file_path_from_user() {
    local PROMPT="$1"
    local OPTIONS=( ${DOX_FILE_PATHS[@]} "Back" )
    local OLD_PS3=$PS3
    PS3="$PROMPT> "
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Back')
                PS3="$OLD_PS3"
                return 1
                ;;
            *)
                local CHECK=`check_item_in_set "$opt" "${OPTIONS[@]}"`
                if [ $? -ne 0 ]; then
                    warning_msg "Invalid option."
                    continue
                fi
                PS3="$OLD_PS3"
                echo "$opt"
                return 0
                ;;
        esac
    done
    PS3="$OLD_PS3"
    return 2
}

function check_item_in_set () {
    local ITEM="$1"
    ITEM_SET=( "${@:2}" )
    for SET_ITEM in "${ITEM_SET[@]}"; do
        if [[ "$ITEM" == "$SET_ITEM" ]]; then
            return 0
        fi
    done
    return 1
}

function search_dox_files() {
    DOX_FILE_PATHS=( `find $ROOT_DIR_PATH -type f -name '*.dox'` )
    if [ ${#DOX_FILE_PATHS[@]} -eq 0 ]; then
        return 1
    fi
    return 0
}

function view_dox_file() {
    local FILE_PATH="$1"
    clear_screen
    $FILE_PATH | more
    local EXIT_CODE=$?
    read -p '
    (DOX)Reader: Press ENTER to continue...'
    return $EXIT_CODE
}

function clear_screen() {
    clear; return $?
}

function display_header() {
    echo ${CYAN}
    cat <<EOF
    ___________________________________________________________________________

     *                        *     $SCRIPT_NAME${CYAN}     *                        *
    ___________________________________________________v.${VERSION}______
               Excellent  Regards, the Alveare Solutions #!/Society -x

EOF
    local EXIT_CODE=$?
    echo ${RESET}
    return $EXIT_CODE
}

function display_usage() {
    display_header
    cat <<EOF
    [ DESCRIPTION ]: Dicover and execute documentation (DOX) scripts in a given
        directory.

    [ USAGE ]: ./`basename $0` <dir-path>

    -h  | --help                Display this message.

    [ EXAMPLE ]: ./`basename $0` ~/Projects/ProjectX

EOF
    return $?
}

function start_dox_menu() {
    local EXIT_CODE=0
    while :
    do
        clear_screen
        display_header
        local FILE_PATH=`fetch_dox_file_path_from_user "$SCRIPT_NAME"`
        if [ -z "$FILE_PATH" ]; then
            break
        fi
        view_dox_file $FILE_PATH
        local EXIT_CODE=$((EXIT_CODE + $?))
    done
    return $EXIT_CODE
}

function init_dox_reader() {
    search_dox_files
    if [ $? -ne 0 ]; then
        echo "[ ${RED}ERROR${RESET} ]: No DOX scripts found in given directory! (${RED}${ROOT_DIR_PATH}${RESET})"
    fi
    start_dox_menu
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ ${RED}WARNING${RESET} ]: Issues detected during last $SCRIPT_NAME session!"
    fi
    echo "
[ ${BLUE}DONE${RESET} ]: Konversation Terminated.
    "
    return $EXIT_CODE
}

# MISCELLANEOUS

if [[ "$ROOT_DIR_PATH" == '-h' ]] || [[ "$ROOT_DIR_PATH" == '--help' ]]; then
    display_usage; exit $?
fi

init_dox_reader
exit $?
