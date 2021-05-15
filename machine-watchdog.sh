#!/bin/bash

declare -A MACHINE_STATES
declare -A MACHINES_STATUS
declare -A MACHINES_TIMESTAMP

# HOT PARAMETERS

TARGETS=()
WATCHDOG_ITERATIONS=0
WATCHDOG_INTERVAL=2

# COLD PARAMETERS

SCRIPT_NAME="WatchDog"
ITERATION_NO=0
MACHINE_STATES=(
['OK']='Online'
['NOK']='Offline'
)
MACHINES_STATUS=()
MACHINES_TIMESTAMP=()

# CHECKERS

function check_machine_status () {
    local MACHINE_ADDR="$1"
    is_alive $ipv4_addr
    if [ $? -ne 0 ]; then
        local STATUS=${MACHINE_STATES['NOK']}
    else
        local STATUS=${MACHINE_STATES['OK']}
    fi
    echo "$STATUS"
    return $?
}

function check_targets_alive () {
    local TARGET_MACHINES=( $@ )
    REPORT_RECORDS=()
    for ipv4_addr in ${TARGETS[@]}; do
        STATUS=`check_machine_status "$ipv4_addr"`
        if [ -z "${MACHINES_TIMESTAMP[$ipv4_addr]}" ] \
                || [[ ! -z "${MACHINES_STATUS[$ipv4_addr]}" ]] \
                && [[ "${MACHINES_STATUS[$ipv4_addr]}" != "$STATUS" ]]; then
            MACHINES_TIMESTAMP[$ipv4_addr]=`date +%c | tr ' ' '-'`
        fi
        MACHINES_STATUS["$ipv4_addr"]=$STATUS
        REPORT_RECORDS=(
            ${REPORT_RECORDS[@]}
            "${MACHINES_TIMESTAMP[$ipv4_addr]},${ipv4_addr},${MACHINES_STATUS[$ipv4_addr]}"
        )
    done
    return $?
}

# SETTERS

function set_watchdog_iteration_interval () {
    local SECONDS=$1
    if [ ! $SECONDS -eq $SECONDS ]; then
        echo "[ WARNING ]: Watchdog iteration interval must be a number"\
            "of seconds, not ($ITER_COUNT)."\
            "Defaulting to ($WATCHDOG_ITERATIONS)."
        return 1
    fi
    WATCHDOG_INTERVAL=$SECONDS
    return 0
}

function set_watchdog_iteration_count () {
    local ITER_COUNT=$1
    if [ ! $ITER_COUNT -eq $ITER_COUNT ]; then
        echo "[ WARNING ]: Watchdog iteration count must be a number,"\
            "not ($ITER_COUNT). Defaulting to ($WATCHDOG_ITERATIONS)."
        return 1
    fi
    WATCHDOG_ITERATIONS=$ITER_COUNT
    return 0
}

# UPDATERS

function update_target_machine_addresses () {
    local TRGT_CSV="$@"
    for ipv4_addr in `echo "$TRGT_CSV" | tr ',' ' '`; do
        TARGETS=( ${TARGETS[@]} "$ipv4_addr" )
    done
    return 0
}

# GENERAL

function is_alive () {
    local IPv4_ADDR="$1"
    ping -c 1 "$IPv4_ADDR" &> /dev/null
    return $?
}

# DISPLAY

function display_usage () {
    cat<<EOF

_______________________________________________________________________________

  *             *            *  Machine Watchdog  *            *            *
_______________________________________________________________________________

    [ USAGE ]: $0

    -h  | --help                Display this message.
    -a= | --machine-address=    Specify IPv4 address of machine you want to
                                monitor. Multiple addresses can be specified
                                seperated by a comma (,)
    -c= | --iteration-count=    Specify the number of times the Watchdog checks
                                to see if the target machines are online.
                                A value of zero (0) means endles monitoring.
                                Default (0)
    -i= | --iteration-interval= Specify the number of seconds to wait before
                                each interogation.

    [ EXAMPLE ]: $0 \\

        (-h | --verbose             )
    - OR -
        (-a | --machine-address     )=127.0.0.1
        (-a | --machine-address     )=127.0.0.2
        (-c | --iteration-count     )=0                     # Endless monitor
        (-i | --iteration-interval  )=2                     # Seconds
    - OR -
        (-a | --machine-address     )=127.0.0.1,127.0.0.2
        (-c | --iteration-count     )=10                    # Pings / machine
        (-i | --iteration-interval  )=5

_______________________________________________________________________________

EOF
    return $?
}

function display_script_name () {
#   figlet "$SCRIPT_NAME"
    if [ $WATCHDOG_ITERATIONS -eq 0 ]; then
        local WD_ITER='-'
    else
        local WD_ITER=$WATCHDOG_ITERATIONS
    fi
    cat<<EOF
       __        __    _       _     ____
       \ \      / /_ _| |_ ___| |__ |  _ \  ___   __ _
        \ \ /\ / / _\` | __/ __| '_ \| | | |/ _ \ / _\` |
         \ V  V / (_| | || (__| | | | |_| | (_) | (_| |
          \_/\_/ \__,_|\__\___|_| |_|____/ \___/ \__, |
                                                 |___/
 Monitoring for ($ITERATION_NO/$WD_ITER) iterations at an interval of ($WATCHDOG_INTERVAL) seconds.
EOF
    return $?
}

function display_header () {
    local HDR_CSV="$1"
    clear; display_script_name
    echo "$HDR_CSV" | awk -F, '
    BEGIN {
        header_format = \
            "________________________________________________________________\n\n"\
            "  %1s %31s %15s\n"\
            "________________________________________________________________\n";
    }
    {
        printf header_format,$1,$2,$3
        print ""
    }' -
    return $?
}

function display_footer () {
    awk -v timestamp="`date`" 'BEGIN {
        footer_format = \
            "________________________________________________________________\n\n"\
            "          Last Update: %s\n"\
            "________________________________________________________________\n"
        printf footer_format,timestamp
    }'
    return 0
}

function display_report_records () {
    local RECORDS=( $@ )
    for report_record in "${RECORDS[@]}"; do
        echo "$report_record" | awk -F, '
        BEGIN {
            format = "  %15s %20s %11s\n"
        }
        {
            printf format,$1,$2,$3
        }' -
    done
    return 0
}

# INIT

function init_watchdog () {
    PING_COUNT=$ITERATION_NO
    while [ ! $PING_COUNT -gt $WATCHDOG_ITERATIONS ]; do
        ITERATION_NO=$((ITERATION_NO + 1))
        if [ $PING_COUNT -ne 0 ] \
                && [ $PING_COUNT -eq $WATCHDOG_ITERATIONS ]; then
            break
        fi
        display_header "TIMESTAMP,MACHINE,STATUS"
        check_targets_alive
        display_report_records ${REPORT_RECORDS[@]}
        display_footer
        if [ $WATCHDOG_ITERATIONS -ne 0 ]; then
            PING_COUNT=$((PING_COUNT + 1))
        fi
        sleep $WATCHDOG_INTERVAL
    done
    return 0
}

# MISCELLANEOUS

for opt in "$@"
do
    case "$opt" in
        -h|--help)
            display_usage
            exit 0
            ;;
        -a=*|--machine-address=*)
            update_target_machine_addresses "${opt#*=}"
            ;;
        -c=*|--iteration-count=*)
            set_watchdog_iteration_count ${opt#*=}
            ;;
        -i=*|--iteration-interval=*)
            set_watchdog_iteration_interval ${opt#*=}
            ;;
    esac
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "[ WARNING ]: No target machine addresses specified!"
    exit 1
fi

init_watchdog
exit $?
