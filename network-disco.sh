#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# NETWORK DISCOVERY

SCRIPT_NAME="(NET)Disco"
NETWORK_RANGE="$1"
PING_COUNT=1
PING_TIMEOUT=1

# CHECKERS

function check_preconditions() {
    if [ -z "$NETWORK_RANGE" ]; then
        return 1
    fi
    return 0
}

# GENERAL

function scan_network_range() {
    local NET_FIRST_OCTETS="$1"
    local NET_RANGE_START="$2"
    local NET_RANGE_END="$3"
    local ONLINE_DEVICES=()
    echo "[ INFO ]: Scanning address range (${NET_FIRST_OCTETS}.${NET_RANGE_START}-${NET_RANGE_END})...
    "
    for octet in `seq $NET_RANGE_START $NET_RANGE_END`; do
        ping -c $PING_COUNT -W $PING_TIMEOUT "${NET_FIRST_OCTETS}.${octet}" &> /dev/null
        if [ $? -ne 0 ]; then
            continue
        fi
        local ONLINE_DEVICES=( ${ONLINE_DEVICES[@]} "ONLINE:${NET_FIRST_OCTETS}.${octet}" )
    done
    if [ ${#ONLINE_DEVICES[@]} -eq 0 ]; then
        return 2
    fi
    echo ${ONLINE_DEVICES[@]} | tr ' ' '\n'
    return $?
}

# DISPLAY

function display_header() {
    cat <<EOF
    ___________________________________________________________________________

     *                        *  Network Discovery  *                        *
    ___________________________________________________________________________
                     Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}

function display_usage() {
    display_header
    cat <<EOF
    [ DESCRIPTION ]: Dicover online device on given network.

    [ USAGE ]: ./`basename $0` <IPv4-Range>

    -h  | --help                Display this message.

    [ EXAMPLE ]: ./`basename $0` 192.168.100.1-30
EOF
    return $?
}

# INIT

function init_network_discovery() {
    display_header
    check_preconditions
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: $SCRIPT_NAME preconditions not met!"
        return 1
    fi
    scan_network_range \
        "`echo $NETWORK_RANGE | cut -d '.' -f 1,2,3`" \
        "`echo $NETWORK_RANGE | cut -d '-' -f 1 | cut -d'.' -f 4`" \
        "`echo $NETWORK_RANGE | cut -d '-' -f 2`"
    return $?
}

# MISCELLANEOUS

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    display_usage
    exit $?
fi

init_network_discovery
exit $?

