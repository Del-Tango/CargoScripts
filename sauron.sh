#!/bin/bash

declare -A SYS_CMD
declare -a IPV4_TARGETS
declare -a ONLINE_TARGETS
declare -a OFFLINE_TARGETS

SCRIPT_NAME='Sauron'
VERSION='HoodWatch'
VERSION_NO='1.0'

# HOT PARAMETERS

IPV4_ADDRS_FILE=''
IPV4_ADDRS_CSV=''
LOG_FILE="${HOME}/.sauron.log"
SILENT='off'
SCAN_INTERVAL='2'       # seconds

# COLD PARAMETERS

IPV4_TARGETS=()
ONLINE_TARGETS=()       # xxx.xxx.xxx.xxx-HH:MM:SS-dd.mm.YYYY
OFFLINE_TARGETS=()      # xxx.xxx.xxx.xxx-HH:MM:SS-dd.mm.YYYY
SYS_CMD=(
['ping-scan']='ping -c 1' # + <ipv4-addrs>
['timestamp']="date +%H:%M:%S-%d.%m.%Y"
)

# Text Colors

RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

# CHECKERS

function check_preconditions () {
    if [ -z "$IPV4_ADDRS_FILE" ] && [ -z "$IPV4_ADDRS_CSV" ]; then
        echo "[ ERROR ]: No target address file or CSV string provided!"
        return 1
    elif [ ! -z "$IPV4_ADDRS_FILE" ] && [ ! -e "$IPV4_ADDRS_FILE" ]; then
        echo "[ ERROR ]: Provided IPv4 address file not found!"
        return 2
    elif [[ "$SILENT" == 'on' ]] && [ -z "$LOG_FILE" ]; then
        echo "[ ERROR ]: Silent execution cannot run without a log file!"
        return 3
    elif [ -z "$SCAN_INTERVAL" ]; then
        echo "[ ERROR ]: No scan interval found!"
        return 4
    fi
    return 0
}

function check_machine_offline () {
    local IPV4_ADDRS="$1"
    for record in ${OFFLINE_TARGETS[@]}; do
        local MACHINE_IPV4=`echo $record | cut -d '-' -f 1`
        if [[ "$MACHINE_IPV4" == "$IPV4_ADDRS" ]]; then
            return 0
        fi
    done
    return 1
}

function check_machine_online () {
    local IPV4_ADDRS="$1"
    for record in ${ONLINE_TARGETS[@]}; do
        local MACHINE_IPV4=`echo $record | cut -d '-' -f 1`
        if [[ "$MACHINE_IPV4" == "$IPV4_ADDRS" ]]; then
            return 0
        fi
    done
    return 1
}

# CLEANERS

function cleanup_from_offline_cache () {
    local IPV4_ADDRS="$1"
    for record in ${OFFLINE_TARGETS[@]}; do
        local MACHINE_IPV4=`echo $record | cut -d '-' -f 1`
        if [[ "$MACHINE_IPV4" != "$IPV4_ADDRS" ]]; then
            continue
        fi
        OFFLINE_TARGETS=("${OFFLINE_TARGETS[@]}/$record")
        return 0
    done
    return 1
}

function cleanup_from_online_cache () {
    local IPV4_ADDRS="$1"
    for record in ${ONLINE_TARGETS[@]}; do
        local MACHINE_IPV4=`echo $record | cut -d '-' -f 1`
        if [[ "$MACHINE_IPV4" != "$IPV4_ADDRS" ]]; then
            continue
        fi
        ONLINE_TARGETS=("${ONLINE_TARGETS[@]}/$record")
        return 0
    done
    return 1
}

# UPDATERS

function update_log_record () {
    local MACHINE_STATE="$1"
    local RECORD="${@:2}"
    local EXPANDED_RECORD=`echo $RECORD | tr '-' '\t'`
    if [[ "$MACHINE_STATE" == "ONLINE" ]]; then
        local FORMATTED_RECORD="[ ${GREEN}${MACHINE_STATE}${RESET} ]: \t${GREEN}${EXPANDED_RECORD}${RESET}"
    elif [[ "$MACHINE_STATE" == "OFFLINE" ]]; then
        local FORMATTED_RECORD="[ ${RED}${MACHINE_STATE}${RESET} ]: \t${RED}${EXPANDED_RECORD}${RESET}"
    else
        local FORMATTED_RECORD="[ ${MACHINE_STATE} ]: \t$EXPANDED_RECORD"
    fi
    if [[ "$SILENT" != 'on' ]]; then
        echo -e "    $FORMATTED_RECORD"
    fi
    if [ ! -z "$LOG_FILE" ]; then
        echo -e "$MACHINE_STATE \t$EXPANDED_RECORD"';' >> $LOG_FILE
    fi
    return $?
}

function update_offline_machines () {
    local IPV4_ADDRS="$1"
    local TIMESTAMP=`${SYS_CMD['timestamp']}`
    local FORMATTED_RECORD="$IPV4_ADDRS"'-'"${TIMESTAMP}"
    OFFLINE_TARGETS=( ${OFFLINE_TARGETS[@]} "$FORMATTED_RECORD" )
    update_log_record 'OFFLINE' "$FORMATTED_RECORD"
    cleanup_from_online_cache "$IPV4_ADDRS"
    return $?
}

function update_online_machines () {
    local IPV4_ADDRS="$1"
    local TIMESTAMP=`${SYS_CMD['timestamp']}`
    local FORMATTED_RECORD="$IPV4_ADDRS"'-'"${TIMESTAMP}"
    ONLINE_TARGETS=( ${ONLINE_TARGETS[@]} "$FORMATTED_RECORD" )
    update_log_record 'ONLINE' "$FORMATTED_RECORD"
    cleanup_from_offline_cache "$IPV4_ADDRS"
    return $?
}

# GENERAL

function process_targets () {
    if [ -z "$IPV4_ADDRS_CSV" ] && [ -z "$IPV4_ADDRS_FILE" ]; then
        return 1
    fi
    if [ ! -z "$IPV4_ADDRS_CSV" ]; then
        IPV4_TARGETS="${IPV4_TARGETS[@]} `echo "${IPV4_ADDRS_CSV}" | tr ',' ' '`"
    fi
    if [ ! -z "$IPV4_ADDRS_FILE" ] && [ -e "$IPV4_ADDRS_FILE" ]; then
        local FL_CONTENT="`cat $IPV4_ADDRS_FILE`"
        if [ ! -z "$FL_CONTENT" ]; then
            IPV4_TARGETS="${IPV4_TARGETS[@]} $FL_CONTENT"
        fi
    fi
    return 0
}

function start_server_monitor () {
    while :; do
        for ipv4_addrs in ${IPV4_TARGETS[@]}; do
            ${SYS_CMD['ping-scan']} ${ipv4_addrs} &> /dev/null
            local EXIT_CODE=$?
            if [ $EXIT_CODE -ne 0 ]; then
                check_machine_offline "$ipv4_addrs" || update_offline_machines "$ipv4_addrs"
            else
                check_machine_online "$ipv4_addrs" || update_online_machines "$ipv4_addrs"
            fi
        done
        sleep $SCAN_INTERVAL
    done
    return 0
}

# DISPLAY

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           *       ${SCRIPT_NAME}      *           *            *
    _____________________________________________________v.${VERSION}___________
                    Regards, the Alveare Solutions #!/Society -x
    "
}

function display_usage () {
    display_header
    cat <<EOF
    [ DESCRIPTION ]: Helps you keep track when a given set of servers go on/offline.

    -h   | --help                Display this message.
    -t=  | --target-file=        File containing target server addresses to scan.
    -c=  | --target-csv=         CSV string containing target server addresses to scan.
    -l=  | --log-file=           File to write update to (Default is STDOUT, no log).
    -i=  | --scan-interval=      Minimum number of seconds between scans of the
                                 same machine.
    -s   | --silent              Flag to suppress STDOUT/STDERR messages.
                                 Implies --log-file=

EOF
    return $?
}

# INIT

function init_sauron () {
    display_header
    check_preconditions
    if [ $? -ne 0 ]; then
        display_usage $@
        return 1
    fi
    process_targets
    start_server_monitor
    return $?
}

# MISCELLANEOUS

if [ ${#@} -eq 0 ]; then
    display_usage
    exit 1
fi

for opt in $@; do
    case "$opt" in
        -h|--help)
            display_usage
            exit 0
            ;;
        -t=*|--target-file=*)
            IPV4_ADDRS_FILE="${opt#*=}"
            ;;
        -c=*|--target-csv=*)
            IPV4_ADDRS_CSV="${opt#*=}"
            ;;
        -i=*|--scan-interval=*)
            SCAN_INTERVAL="${opt#*=}"
            ;;
        -s|--silent)
            SILENT="on"
            ;;
    esac
done

case "$SILENT" in
    'on')
        init_sauron &> /dev/null
        ;;
    *)
        init_sauron
        ;;
esac

EXITT_CODE=$?
echo; exit $EXIT_CODE

