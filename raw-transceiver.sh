#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
TARGET_ADDRESS='127.0.0.1' # Number of messages to expect. 0 indicates endless litening
PORT_NUMBER=8080
MESSAGE="`date` - (`whoami`) Conscript Reporting! `pwd`"

# SETTERS

function set_message () {
    local MSG="$@"
    MESSAGE="$MSG"
    return 0
}

function set_target_address () {
    local MACHINE_ADDR="$1"
    TARGET_ADDRESS="$MACHINE_ADDR"
    return 0
}

function set_port_number () {
    local PORT=$1
    check_is_integer $PORT
    if [ $? -ne 0 ]; then
        echo "[ ERROR ]: Port number value must be a number, not ($PORT)."
        return 1
    fi
    PORT_NUMBER=$PORT
    return 0
}

# CHECKERS

function check_is_integer () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    return $?
}

# GENERAL

function raw_transceiver () {
    local ADDR="$1"
    local PORT_NO="$2"
    local MSG="${@:3}"
    echo "$MSG" | ncat "$ADDR" $PORT_NO &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Message not sent! ($ADDR - $PORT_NO - $MSG)"
        return 1
    else
        echo "[ OK ]: Message sent! ($ADDR - $PORT_NO - $MSG)"
    fi
    return $?
}

# FORMATTERS

# DISPLAY

function display_target_address () {
    if [ -z "$TARGET_ADDRESS" ]; then
        local TA_LABEL="Unspecified"
    else
        local TA_LABEL="$TARGET_ADDRESS"
    fi
    echo "    [ TARGET ADDRESS   ]: $TA_LABEL"
    return $?
}

function display_port_number () {
    if [ -z "$PORT_NUMBER" ]; then
        local PN_LABEL="Unspecified"
    else
        local PN_LABEL="$PORT_NUMBER"
    fi
    echo "    [ PORT NUMBER      ]: $PN_LABEL"
    return $?
}

function display_message () {
    if [ -z "$MESSAGE" ]; then
        local MS_LABEL="Unspecified"
    else
        local MS_LABEL="$MESSAGE"
    fi
    echo "    [ MESSAGE          ]: ${MS_LABEL:0:55}..."
    return $?
}

function display_usage () {
    display_header
    cat<<EOF

    [ DESCRIPTION ]: Socket Transceiver.

    [ USAGE ]: $0 -<option>=<value>

    -h  | --help                Display this message.
    -a= | --target-address=     IPv4 address of raw socket server listening for
                                incomming connections.
    -p= | --port-number=        Port number used to comunicate with server at
                                the specified address.
    -m= | --message=            The message to send.

    [ EXAMPLE ]: $0

    (-p | --port-number         )=5432
    (-a | --target-address      )="127.0.0.1"
    (-m | --message             )="\`date\` - (\`whoami\`) - Conscript Reporting!"

EOF
    return $?
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *          * Raw Socket Transceiver *          *           *
    ___________________________________________________________________________
                        Regards, the Alveare Solutions society."
}

function display_banner () {
    display_header; echo
    display_target_address
    display_port_number
    display_message
    echo; return 0
}

# INIT

function init_raw_transceiver () {
    raw_transceiver "$TARGET_ADDRESS" $PORT_NUMBER "$MESSAGE"
    local EXIT_CODE=$?
    echo; return $EXIT_CODE
}

# MISCELLANEOUS

if [ $# -eq 0 ]; then
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
        -p=*|--port-number=*)
            set_port_number "${opt#*=}"
            ;;
        -a=*|--target-address=*)
            set_target_address "${opt#*=}"
            ;;
        -m=*|--message=*)
            set_message "${opt#*=}"
            ;;
    esac
done

display_banner
init_raw_transceiver

exit $?

