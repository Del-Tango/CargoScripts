#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# RAW SOCKET LISTENER
ITERATION_COUNT=0 # Number of messages to expect. 0 indicates endless litening
PORT_NUMBER=8080
TARGET='stdout' # (file | pipe | stdout)
OUT_FILE_PATH=""
OUT_FIFO_PATH=""
SILENT='off'

# SETTERS

function set_silent_flag () {
    local FLAG="$1"
    if [[ "$FLAG" != 'on' ]] && [[ "$FLAG" != 'off' ]]; then
        log_msg "[ WARNING ]: Invalid silent flag ($FLAG)."\
            "Defaulting to ($SILENT)."
        return 1
    fi
    SILENT="$FLAG"
    return 0
}

function set_output_fifo_path () {
    local FIFO_PATH="$1"
    if [ ! -p "$FIFO_PATH" ]; then
        log_msg "[ WARNING ]: No named pipe found at ($FIFO_PATH)."\
            "Building..."
        mkfifo $FIFO_PATH &> /dev/null
        if [ $? -eq 0 ]; then
            log_msg "[ OK ]: Successfully created named pipe ($FIFO_PATH)."
        else
            log_msg "[ NOK }: Could not create named pipe ($FIFO_PATH)."
            return 1
        fi
    fi
    OUT_FIFO_PATH="$FIFO_PATH"
    return 0
}

function set_output_file_path () {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ]; then
        log_msg "[ WARNING ]: No file found at ($FILE_PATH)."\
            "Building..."
        touch $FILE_PATH &> /dev/null
        if [ $? -eq 0 ]; then
            log_msg "[ OK ]: Successfully created file ($FILE_PATH)."
        else
            log_msg "[ NOK }: Could not create file ($FILE_PATH)."
            return 1
        fi
    fi
    OUT_FILE_PATH="$FILE_PATH"
    return 0
}

function set_iteration_count () {
    local ITERATIONS=$1
    check_is_integer $ITERATIONS
    if [ $? -ne 0 ]; then
        log_msg "[ ERROR ]: Raw listener iteration count must be a number,"\
            "not ($ITERATIONS)."
        return 1
    fi
    ITERATION_COUNT=$ITERATIONS
    return 0
}

function set_target () {
    local MSG_DST="$1"
    if [[ "$MSG_DST" != 'stdout' ]] \
            && [[ "$MSG_DST" != 'file' ]] \
            && [[ "$MSG_DST" != 'pipe' ]]; then
        log_msg "[ WARNING ]: Invalid message destination ($MSG_DST)."\
            "Defaulting to (single)."
        local MSG_DST='single'
    fi
    TARGET="$MSG_DST"
    return 0
}

function set_port_number () {
    local PORT=$1
    check_is_integer $PORT
    if [ $? -ne 0 ]; then
        log_msg "[ ERROR ]: Port number value must be a number, not ($PORT)."
        return 1
    fi
    PORT_NUMBER=$PORT
    return 0
}

# CHECKERS

function check_silent_on () {
    if [[ "$SILENT" != 'on' ]]; then
        return 1
    fi
    return 0
}

function check_is_integer () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    return $?
}

# GENERAL

function log_msg () {
    local MSG="$@"
    check_silent_on
    if [ $? -eq 0 ]; then
        return 1
    fi
    echo "$MSG"
    return $?
}

function raw_listener () {
    local PORT_NO=$1
    local MSG_DST="$2"
    case "$MSG_DST" in
        'stdout')
            local OUTPUT="-"
            ;;
        'file')
            local OUTPUT="$OUT_FILE_PATH"
            ;;
        'pipe')
            local OUTPUT="$OUT_PIPE_PATH"
            ;;
        *)
            log_msg "[ ERROR ]: Invalid message destination ($MSG_DST)."
            return 1
            ;;
    esac
    ncat -l -p $PORT_NO 2>&1 | tee -a "$OUTPUT"
    return $?
}

# FORMATTERS

# DISPLAY

function display_banner () {
    check_silent_on
    if [ $? -eq 0 ]; then
        return 1
    fi
    display_header; echo
    display_target
    display_port_number
    display_iterations
    display_output_file
    display_output_fifo
    echo; return 0
}


function display_target () {
    if [ -z "$TARGET" ]; then
        local TA_LABEL="Unspecified"
    else
        local TA_LABEL="$TARGET"
    fi
    log_msg "    [ TARGET           ]: $TA_LABEL"
    return $?
}

function display_port_number () {
    if [ -z "$PORT_NUMBER" ]; then
        local PN_LABEL="Unspecified"
    else
        local PN_LABEL="$PORT_NUMBER"
    fi
    log_msg "    [ PORT NUMBER      ]: $PN_LABEL"
    return $?
}

function display_iterations () {
    if [ -z "$ITERATION_COUNT" ]; then
        IC_LABEL="Unspecified"
    fi
    case "$ITERATION_COUNT" in
        "0")
            local IC_LABEL="Endless"
            ;;
        *)
            local IC_LABEL="$ITERATION_COUNT"
            ;;
    esac
    log_msg "    [ ITERATIONS       ]: $IC_LABEL"
    return $?
}

function display_output_file () {
    if [ -z "$OUT_FILE_PATH" ]; then
        return 1
    fi
    log_msg "    [ OUTPUT FILE      ]: $OUT_FILE_PATH"
    return $?
}

function display_output_fifo () {
    if [ -z "$OUT_FIFO_PATH" ]; then
        return 1
    fi
    log_msg "    [ OUTPUT FIFO      ]: $OUT_FIFO_PATH"
    return $?

}

function display_usage () {
    display_header
    local SCRIPT_NAME=`basename $0`
    cat<<EOF

    [ DESCRIPTION ]: Socket Listener.

    [ USAGE ]: $SCRIPT_NAME -<option>=<value>

    -h  | --help                Display this message.
    -s  | --silent              Display only messages received, no program dialogue.
    -p= | --port-number=        Port number to listen on for incomming connections.
    -i= | --iterations=         Number of messages to expect the listener to receive.
                                A value of 0 (zero) initiates endless listening.
    -t= | --target=             Target destination of received message.
                                (stdout | file | pipe)
    -F= | --output-file=        File path to redirect message to. Implies (-t='file').
    -P= | --output-pipe=        FIFO path to redirect message to. Implies (-t='pipe')

    [ EXAMPLE ]: $SCRIPT_NAME

    (-s | --silent              )
    (-p | --port-number         )=5432
    (-i | --iterations          )=0
    (-t | --target              )=file       # (stdout | file | pipe)
    (-F | --output-file         )=/var/rsl/rsl.out

EOF
    return $?
}

function display_header () {
    log_msg "
    ___________________________________________________________________________

     *            *           * Raw Socket Listener *            *           *
    ___________________________________________________________________________
                        Regards, the Alveare Solutions society."
}

# INIT

function init_raw_listener () {
    COUNT=0
    while :
    do
        if [ $COUNT -ne 0 ] && [ $COUNT -eq $ITERATION_COUNT ]; then
            break
        fi
        raw_listener $PORT_NUMBER "$TARGET"
        COUNT=$((COUNT + 1))
    done
    return $?
}

# MISCELLANEOUS

if [ $# -eq 0 ]; then
    log_msg "[ ERROR ]: Invalid number of arguments ($#)."
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
        -s|--silent)
            set_silent_flag 'on'
            ;;
        -p=*|--port-number=*)
            set_port_number "${opt#*=}"
            ;;
        -i=*|--iterations=*)
            set_iteration_count "${opt#*=}"
            ;;
        -t=*|--target=*)
            set_target "${opt#*=}"
            ;;
        -F=*|--output-file=*)
            set_output_file_path "${opt#*=}"
            ;;
        -P=*|--output-pipe=*)
            set_output_fifo_path "${opt#*=}"
            ;;
    esac
done

display_banner
init_raw_listener

exit $?


