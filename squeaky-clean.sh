#!/bin/bash
#
# Excellent Regards, the Alveare Solutions #!/Society -x
#
# SqueakyClean
# ______________________________________________________________________________
# _______________  *                     *____________________*_________________
# |              \
# | sPOT(m@e)LESs \   Almost (D.F.E) - Legacy of ShredderBay
# | _____________  \___________________________________________
# |
# |[ DESCRIPTION ]: Cleanup poluted files/devices on target machine post-exploit.
# |  Players with squeakyclean spotless machines will inevitably spot-you-less ;)
# |
# |[ DISCLAIMER ]: Thats right ladies && gents! You observed correctly! This is
# |  a three-start cargo script, which means that it's not a pasive tool like
# |  the - ugh - two start cargo scripts, and can do some serious damage if used
# |  improperly.
# |
# |  This script is designed for wargaming only! Don't be a karma chaser. Do NOT
# |  use this on a system you do not own! Destruction of data you don't own is
# |  just asking for it from the man, man! You're smarter than that now.
# |
# |  But, you know, shit happens - and if you do decide to be that **person**
# |  (assholes come in many forms && flavours) good luck to ya, keep us out of it.
# |  You could still contribute tho, we always love getting your input and pull req.
# |______________________________________
# _________________*_____________________*____________________*_________________
#

declare -A DEFAULT
declare -A LOCATIONS
declare -a DEPENDENCIES

SCRIPT_NAME='SqueakyClean'
VERSION='(sPOT(m@e)LESs)'
VERSION_NO='v1.0'
DEFAULT=(
['clean-type']='files'
['clean']=''
['dir-regex']='*'
['file-regex']='*.log,.*'
['block-device-regex']='mmcblk*'
['shred']='off'
['self-destruct']='off'
['nuke']='off'
['silent']='off'
['safety']='on'
['hide-shred']='on'
['shredder-patterns']='zero,random,custom'
['shredder-passes']=10
['custom-pattern']='FUUUUuUuUuu'
['location-file']='.sc.loc'
['block-size']=512
)
LOCATIONS=(
['ssh']="${HOME}/.ssh,/etc/sshd,/etc/ssh"
['scp']="${HOME}/.scp,/etc/scp"
['log']='/etc,/var/log'
['home']='/home,/root'
['devices']='/dev'
)
DEPENDENCIES=(
'shred'
'dd'
'find'
'xargs'
'awk'
'cat'
'echo'
'lsblk'
'tr'
'fdisk'
'grep'
'pv'
)

# DISPLAY

function display_header() {
    cat<<EOF
    ___________________________________________________________________________

     *              *            *  ${SCRIPT_NAME}  *           *              *
    _________________________________________________${VERSION_NO}${VERSION}_______
              Excellent Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}

function display_usage() {
    display_header
    cat<<EOF
[ USAGE ]:

    -h | --help                   Display this message.

       | --setup                  Install cargo script dependencies.

    -q | --silent                 Quiet flag - suppress STDOUT/STDERR messages.

    -c | --clean=             CSV Specify what to cleanup.

       |                          For --clean-type=files, valid clean targets
       |                          would be the location keys for a supported tool
       |                          or special directory - given as a CSV string.
       |                          (ssh,scp,log,home).

       |                          For --clean-type=directories, valid clean
       |                          targets would be standard system directories.
       |                          (cron,log,home)

       |                          For --clean-type=devices, valid clean targets
       |                          would be all or unspecified, the SC tool taking
       |                          into account the --block-device-regex=.

    -t | --clean-type=        CSV Specify how the cleanup should be handled.

       |                          Valid values are (files|directories|devices).

    -d | --directory-regex=   CSV Specify what directories to remove/shred.

    -f | --file-regex=        CSV Specify what files to remove/shred.

    -b | --block-device-regex=CSV Specify what block devices to shred.

    -B | --block-size=       SIZE Specify what block size to use when applying
       |                          overwrite patterns during block device shred.

    -C | --cron-locations=    CSV Specify cron file directories.

    -L | --log-locations=     CSV Specify log file directories.

    -D | --device-locations=  CSV Specify block device directories.

    -H | --home-locations=    CSV Specify user home directories.

    -s | --shred                  Flag to shred (low level overwrite with zeroes,
       |                          random data or specified custom pattern) the
       |                          data, not just unlink it and mark as free.

    -S | --self-destruct          Flag to initiate the self-destruct sequence
       |                          after cleanup.

       |             [ WARNING ]: If a location file is specified, it will also
       |                          be removed along with the cargo script.

    -N | --nuke                   Remove squeaky clean parent directory during
       |                          the self-destruct sequence.

    -p | --shredder-patterns= CSV Specify what to overwrite the data with and in
       |                          what order when --shred mode is used on block
       |                          devices.

       |                          Valid values are (zero | random | custom).

       |             [ WARNING ]: Shredder patterns are applicable to storage
       |                          devices only! Will not be used on files and
       |                          directories.

    -e | --custom-erasure-pattern=STRING Used to overwrite block devices during
       |                          device shredding operation.

    -l | --locations-file=FILE_PATH - BASH Format - file is sourced:
       |                          '''
       |                          LOCATIONS=(
       |                            ['key']='/location1,/location2'
       |                            ['...
       |                          )
       |                          ''' > ./.sc.loc

       |             [ WARNING ]: The contents of this file will completely
       |                          overwrite the default LOCATIONS array. Make
       |                          sure all required locations are defined.

    -P | --shredder-passes=ITERATIONS Specify how many passes the shredder
       |                          should make over each file, or how many times
       |                          a shredding pattern should apply when DFE-ing
       |                          storage devices.

    -z | --hide-shred             Specify that a zero-out overwrite should be
       |                          done after any sort of shredding in order to
       |                          hide it.

[ EXAMPLE ]: Install dependencies.

    $ ./`basename $0` --setup

[ EXAMPLE ]: Shred all devices found in location named sd* and mmcblk* using
             overwrite patterns 1 - zero-out, 2 - random-data, 3 - custom string.
             Each erasure pattern will be written to the block device 10 times.

             After shred is complete the script will remove itself from the file
             system as well as the locations file .sc.loc, but not before hiding
             the fact that the devices were shredded, which means it will
             overwrite everything with zeroes.

    $ ./`basename $0` \\
        -c | --clean='devices' \\
        -t | --clean-type='devices' \\
        -p | --shredder-patterns='zero,random,custom' \\
        -P | --shredder-passes=10 \\
        -e | --custom-erasure-pattern='FUUUUuUuUuu' \\
        -b | --block-device-regex='sd*,mmcblk*' \\
        -B | --block-size=512 \\
        -l | --locations-file='.sc.loc' \\
        -z | --hide-shred \\
        -S | --self-destruct

[ EXAMPLE ]: Shred poluted files for system utils ssh and scp. Remove the parent
             directory of the cargo script upon completion, as well as the
             specified locations file.

    $ ./`basename $0` \\
        -c | --clean='ssh,scp' \\
        -t | --clean-type='files' \\
        -f | --file-regex='*.log,.*' \\
        -l | --locations-file='.sc.loc' \\
        -S | --self-destruct \\
        -N | --nuke \\
        -s | --shred \\
        -z | --hide-shred

[ EXAMPLE ]: Remove all log files, hidden files and user home files without
             shredding the data (because that takes a relatively long time),
             followed by the specified directories matching regex patterns in
             locations log and home.

             Specify locations via the command line and not a .loc file.

    $ ./`basename $0` \\
        -c | --clean='ssh,scp' \\
        -t | --clean-type='files' \\
        -f | --file-regex='*.log,.*' \\
        -d | --directory-regex='.shady*' \\
        -H | --home-locations='/home,/root' \\
        -L | --log-locations='/etc,/var/log'

EOF
    return $?
}

# MESSAGES

function msg_safety_warning() {
    echo "[ WARNING ]: $SCRIPT_NAME safety is ON!"
    return $?
}

function msg_action_nok() {
    local TYPE="$1"
    local TARGET="$2"
    echo "[ NOK ]: Something went wrong! Could not ${TYPE} ${TARGET} :'("
    return $?
}

function msg_action_ok() {
    local TYPE="$1"
    local TARGET="$2"
    echo "[ OK ]: ${TYPE} ${TARGET} :')"
    return $?
}

# FETCHERS

function fetch_device_size() {
    local TARGET_DEVICE="$1"
    local SIZE=`lsblk -bo NAME,SIZE "$TARGET_DEVICE" | grep -e '^[a-z].*' \
        | awk '{print $NF}'`
    if [ -z "$SIZE" ]; then
        return 1
    fi
    echo "$SIZE"
    return $?
}

# GENERAL

function shred_cmd() {
    local TARGET="$1"
    local LOCATION_CSV="$2"
    local TARGET_REGEX_CSV="$3"
    local SHREDDER_PATTERNS="$4"
    local COMMAND=()
    local EXIT_CODE=0
    for location_label in `echo ${LOCATION_CSV} | tr ',' ' '`; do
        case "$TARGET" in
            'files')
                local COMMAND=(
                    `format_command_file_shred \
                        "${location_label}" "${TARGET_REGEX_CSV}"`
                )
                ;;
            'directories')
                local COMMAND=(
                    `format_command_directory_shred \
                        "${location_label}" "${TARGET_REGEX_CSV}"`
                )
                ;;
            'devices')
                local COMMAND=(
                    `format_command_device_shred \
                        "${location_label}" "${TARGET_REGEX_CSV}" \
                        "${SHREDDER_PATTERNS}"`
                )
                ;;
            *)
                echo "[ ERROR ]: Invalid Shred CMD Target! (${TARGET})"
                return 1
                ;;
        esac
        if [ ${#COMMAND[@]} -eq 0 ]; then
            echo "[  :|  ]: Nothing to do here."
        else
            echo "[ CMD ]: Running: ${COMMAND[@]}"
            ${COMMAND[@]} &> /dev/null
        fi
        local EXIT_CODE=$((EXIT_CODE+$?))
    done
    return $EXIT_CODE
}

function clean_cmd() {
    local TARGET="$1"
    local LOCATION_CSV="$2"
    local TARGET_REGEX_CSV="$3"
    local COMMAND=()
    local EXIT_CODE=0
    for location_label in `echo ${LOCATION_CSV} | tr ',' ' '`; do
        case "$TARGET" in
            'files')
                local COMMAND=(
                    `format_command_file_cleanup \
                        "${location_label}" "${TARGET_REGEX_CSV}"`
                )
                ;;
            'directories')
                local COMMAND=(
                    `format_command_directory_cleanup \
                        "${location_label}" "${TARGET_REGEX_CSV}"`
                )
                ;;
            *)
                echo "[ ERROR ]: Invalid Clean CMD Target! (${TARGET})"
                return 1
                ;;
        esac
        if [ ${#COMMAND[@]} -eq 0 ]; then
            echo "[  :|  ]: Nothing to do here."
            local EXIT_CODE=$((EXIT_CODE+1))
        else
            echo "[ CMD ]: Running: ${COMMAND[@]}"
            ${COMMAND[@]} &> /dev/null
        fi
        local EXIT_CODE=$((EXIT_CODE+$?))
    done
    return $EXIT_CODE
}

function shred_devices() {
    if [[ "${DEFAULT['safety']}" == 'on' ]]; then
        msg_safety_warning; return 1
    fi
    local LOCATION_CSV="`format_location_csv_for_cmd`"
    shred_cmd 'devices' "${LOCATION_CSV}" "${DEFAULT['block-device-regex']}" \
        "${DEFAULT['shredder-patterns']}"
    return $?
}

function shred_directories() {
    if [[ "${DEFAULT['safety']}" == 'on' ]]; then
        msg_safety_warning; return 1
    fi
    local LOCATION_CSV="`format_location_csv_for_cmd`"
    shred_cmd 'devices' "${LOCATION_CSV}" "${DEFAULT['dir-regex']}"
    return $?
}

function shred_files() {
    if [[ "${DEFAULT['safety']}" == 'on' ]]; then
        msg_safety_warning; return 1
    fi
    local LOCATION_CSV="`format_location_csv_for_cmd`"
    shred_cmd 'files' "${LOCATION_CSV}" "${DEFAULT['file-regex']}"
    return $?
}

function cleanup_files() {
    if [[ "${DEFAULT['safety']}" == 'on' ]]; then
        msg_safety_warning; return 1
    fi
    local LOCATION_CSV="`format_location_csv_for_cmd`"
    clean_cmd 'files' "${LOCATION_CSV}" "${DEFAULT['file-regex']}"
    return $?
}

function cleanup_directories() {
    if [[ "${DEFAULT['safety']}" == 'on' ]]; then
        msg_safety_warning; return 1
    fi
    local LOCATION_CSV="`format_location_csv_for_cmd`"
    clean_cmd 'directories' "${LOCATION_CSV}" "${DEFAULT['dir-regex']}"
    return $?
}

# ACTIONS

function action_cleanup_files() {
    cleanup_files
    if [ $? -ne 0 ]; then
        msg_action_nok 'remove' 'files'
        return 1
    fi
    msg_action_ok 'Files' 'removed'
    return 0
}

function action_cleanup_directories() {
    cleanup_directories
    if [ $? -ne 0 ]; then
        msg_action_nok 'remove' 'directories'
        return 1
    fi
    msg_action_ok 'Directories' 'removed'
    return 0
}

function action_shred_files() {
    shred_files
    if [ $? -ne 0 ]; then
        msg_action_nok 'shred' 'files'
        return 1
    fi
    msg_action_ok 'Files' 'shredded'
    return 0
}

function action_shred_directories() {
    shred_directories
    if [ $? -ne 0 ]; then
        msg_action_nok 'shred' 'directories'
        return 1
    fi
    msg_action_ok 'Directories' 'shredded'
    return 0
}

function action_shred_devices() {
    if [ $EUID -ne 0 ]; then
        echo "[ WARNING ]: Action requires priviledged access rights!"\
            "Are you root?"
        return 1
    fi
    echo "[ INFO ] : This may really take a while,"\
        "do something cool in the mean time ;)"
    shred_devices; local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        msg_action_nok 'shred' 'devices'
    else
        msg_action_ok 'Devices' 'shredded'
    fi
    return $EXIT_CODE
}

# FORMATTERS

function format_command_file_shred() {
    # [ NOTE ]: Required shred args
    # -f, --force
    #       change permissions to allow writing if necessary
    # -n, --iterations=N
    #       ovewrite N times instead of the default (3)
    # -u    deallocate and  remove file after overwriting
    # -x, --exact
    #       do not round file sizes up to the next full block;
    #       this is the default for non-regular files
    # -z, --zero
    #       add a final overwrite with zeroes to hide shredding
    local LOCATION_LABEL="$1"
    local FILE_REGEX_CSV="$2"
    local DISCOVERY_COMMAND=(
        'find' "${LOCATIONS[${LOCATION_LABEL}]}" '-type' 'f' '(' '-name'
    )
    local COMMAND=()
    local FIRST_PATTERN=
    for regex_pattern in `echo "'${FILE_REGEX_CSV}'" | tr ',' ' ' | tr "'" ' ' | xargs`; do
        if [ -z "$regex_pattern" ]; then
            continue
        elif [ -z "$FIRST_PATTERN" ]; then
            local DISCOVERY_COMMAND=(
                ${DISCOVERY_COMMAND[@]} "${regex_pattern}"
            )
            local FIRST_PATTERN="${regex_pattern}"
            continue
        fi
        local DISCOVERY_COMMAND=(
            ${DISCOVERY_COMMAND[@]} '-o' '-name' "${regex_pattern}"
        )
    done
    local DISCOVERY_COMMAND=( ${DISCOVERY_COMMAND[@]} ')' )
    local COMMAND=(
        ${DISCOVERY_COMMAND[@]} '|' 'xargs' 'shred' '--force'
        "--iterations=${DEFAULT['shredder-passes']}" '--exact' '-u'
    )
    if [[ "${DEFAULT['hide-shred']}" == 'on' ]]; then
        local COMMAND=( ${COMMAND[@]} '--zero' )
    fi
    local COMMAND=( ${COMMAND[@]} ';')
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_directory_shred() {
    # [ NOTE ]: Required shred args
    # -f, --force
    #       change permissions to allow writing if necessary
    # -n, --iterations=N
    #       ovewrite N times instead of the default (3)
    # -u    deallocate and  remove file after overwriting
    # -x, --exact
    #       do not round file sizes up to the next full block;
    #       this is the default for non-regular files
    # -z, --zero
    #       add a final overwrite with zeroes to hide shredding
    local LOCATION_LABEL="$1"
    local DIR_REGEX_CSV="$2"
    local DISCOVERY_COMMAND=(
        'find' "${LOCATIONS[${LOCATION_LABEL}]}" '-type' 'd' '(' '-name'
    )
    local COMMAND=()
    local FIRST_PATTERN=
    for regex_pattern in `echo "'${DIR_REGEX_CSV}'" | tr ',' ' ' | tr "'" ' ' | xargs`; do
        if [ -z "$regex_pattern" ]; then
            continue
        elif [ -z "$FIRST_PATTERN" ]; then
            local DISCOVERY_COMMAND=(
                ${DISCOVERY_COMMAND[@]} "${regex_pattern}"
            )
            local FIRST_PATTERN="${regex_pattern}"
            continue
        fi
        local DISCOVERY_COMMAND=(
            ${DISCOVERY_COMMAND[@]} '-o' '-name' "${regex_pattern}"
        )
    done
    local DISCOVERY_COMMAND=( ${DISCOVERY_COMMAND[@]} ')' )
    for dir_path in `${DISCOVERY_COMMAND[@]}`; do
        local COMMAND=(
            ${COMMAND[@]} 'find' "${dir_path}" '-type' 'f' '|' 'xargs' 'shred'
            '--force' "--iterations=${DEFAULT['shredder-passes']}" '--exact' '-u'
        )
        if [[ "${DEFAULT['hide-shred']}" == 'on' ]]; then
            local COMMAND=( ${COMMAND[@]} '--zero' )
        fi
        local COMMAND=( ${COMMAND[@]} ';')
    done
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_device_shred_pattern_zero() {
    local TARGET_DEV="$1"
    local DEV_SIZE=`fetch_device_size "$TARGET_DEV"`
    local BLOCKS="$((DEV_SIZE / ${DEFAULT['block-size']}))"
    local COMMAND=(
        'dd' 'if=/dev/zero' "bs=${DEFAULT['block-size']}" "count=${BLOCKS}" '|'
        'pv' '-ptebar' '--size' "${DEV_SIZE}" '|' 'dd' "of=${TARGET_DEV}"
        "bs=${DEFAULT['block-size']}" "count=${BLOCKS}"
    )
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_device_shred_pattern_random() {
    local TARGET_DEV="$1"
    local DEV_SIZE=`fetch_device_size "$TARGET_DEV"`
    local BLOCKS="$((DEV_SIZE / ${DEFAULT['block-size']}))"
    local COMMAND=(
        'dd' 'if=/dev/random' "bs=${DEFAULT['block-size']}" "count=${BLOCKS}" '|'
        'pv' '-ptebar' '--size' "${DEV_SIZE}" '|' 'dd' "of=${TARGET_DEV}"
        "bs=${DEFAULT['block-size']}" "count=${BLOCKS}"
    )
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_device_shred_pattern_custom() {
    local TARGET_DEV="$1"
    local DEV_SIZE=`fetch_device_size "$TARGET_DEV"`
    local BLOCKS="$((DEV_SIZE / ${DEFAULT['block-size']}))"
    local COMMAND=(
        'yes' "${DEFAULT['custom-pattern']}" '|' 'dd' "bs=${DEFAULT['block-size']}"
        "count=${BLOCKS}" '|' 'pv' '-ptebar' '--size' "${DEV_SIZE}" '|' 'dd'
        "of=${TARGET_DEV}" "bs=${DEFAULT['block-size']}" "count=${BLOCKS}"
    )
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_device_shred() {
    local LOCATION_LABEL="$1"
    local DEV_REGEX_CSV="$2"
    local SHREDDER_PATTERNS_CSV="$3"
    local DISCOVERY_COMMAND=(
        'find' "${LOCATIONS[${LOCATION_LABEL}]}" '-type' 'b' '(' '-name'
    )
    local COMMAND=()
    local FIRST_PATTERN=
    for regex_pattern in `echo "'${DEV_REGEX_CSV}'" | tr ',' ' ' | tr "'" ' ' | xargs`; do
        if [ -z "$regex_pattern" ]; then
            continue
        elif [ -z "$FIRST_PATTERN" ]; then
            local DISCOVERY_COMMAND=(
                ${DISCOVERY_COMMAND[@]} "${regex_pattern}"
            )
            local FIRST_PATTERN="${regex_pattern}"
            continue
        fi
        local DISCOVERY_COMMAND=(
            ${DISCOVERY_COMMAND[@]} '-o' '-name' "${regex_pattern}"
        )
    done
    local DISCOVERY_COMMAND=( ${DISCOVERY_COMMAND[@]} ')' )
    for device_path in `${DISCOVERY_COMMAND[@]}`; do
        if [[ ! -z "${COMMAND[@]}" ]]; then
            local COMMAND=(
                ${COMMAND[@]} '&&' `format_command_device_shred_pattern \
                    "${device_path}" "${SHREDDER_PATTERNS_CSV}"`
            )
        else
            local COMMAND=(
                `format_command_device_shred_pattern "${device_path}" \
                    "${SHREDDER_PATTERNS_CSV}"`
            )
        fi
    done
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_device_shred_pattern() {
    local DEVICE_PATH="$1"
    local SHREDDER_PATTERNS_CSV="$2"
    declare -A HANDLERS
    local COMMAND=()
    HANDLERS=(
        ['zero']='format_command_device_shred_pattern_zero'
        ['random']='format_command_device_shred_pattern_random'
        ['custom']='format_command_device_shred_pattern_custom'
    )
    for pattern in `echo ${SHREDDER_PATTERNS_CSV} | tr ',' ' '`; do
        if [ ${#COMMAND[@]} -ne 0 ]; then
            local COMMAND=(
                ${COMMAND[@]} '&&'
                `${HANDLERS[${pattern}]} "${DEVICE_PATH}" "${SHREDDER_PATTERNS_CSV}"`
            )
        else
            local COMMAND=(
                `${HANDLERS[${pattern}]} "${DEVICE_PATH}" "${SHREDDER_PATTERNS_CSV}"`
            )
        fi
    done; echo -n ${COMMAND[@]}
    return $?
}

function format_command_file_cleanup() {
    local LOCATION_LABEL="$1"
    local FILE_REGEX_CSV="$2"
    local COMMAND=(
        'find' "${LOCATIONS[${LOCATION_LABEL}]}" '-type' 'f' '(' '-name'
    )
    for regex_pattern in `echo "'${FILE_REGEX_CSV}'" | tr ',' ' ' | tr "'" ' ' | xargs`; do
        if [ ${#COMMAND[@]} -ne 0 ]; then
            local COMMAND=(
                ${COMMAND[@]} '-o' '-name' "'${regex_pattern}'"
            )
        else
            local COMMAND=(
                ${COMMAND[@]} "'${regex_pattern}'"
            )
        fi
    done
    local COMMAND=( ${COMMAND[@]} ')' '|' 'xargs' 'rm' '-f')
    echo -n "${COMMAND[@]}"
    return $?
}

function format_command_directory_cleanup() {
    local LOCATION_LABEL="$1"
    local DIR_REGEX_CSV="$2"
    local COMMAND=(
        'find' "${LOCATIONS[${LOCATION_LABEL}]}" '-type' 'd' '(' '-name'
    )
    for regex_pattern in `echo "'${DIR_REGEX_CSV}'" | tr ',' ' ' | tr "'" ' ' | xargs`; do
        if [ ${#COMMAND[@]} -ne 0 ]; then
            local COMMAND=(
                ${COMMAND[@]} '-o' '-name' "'${regex_pattern}'"
            )
        else
            local COMMAND=(
                ${COMMAND[@]} "'${regex_pattern}'"
            )
        fi
    done
    local COMMAND=( ${COMMAND[@]} ')' '|' 'xargs' 'rm' '-rf')
    echo -n "${COMMAND[@]}"
    return $?
}

function format_location_csv_for_cmd() {
    if [[ "${DEFAULT['clean']}" == 'all' ]]; then
        local LOCATION_CSV="`echo ${LOCATIONS[@]} | tr ' ' ','`"
    else
        local LOCATION_CSV="${DEFAULT['clean']}"
    fi
    echo -n "$LOCATION_CSV"
    return $?
}

# INSTALLERS

function apt_install_dependency() {
    local UTILS=( $@ )
    echo "[ + ]: Packages (${UTILS[@]})..."
    apt-get install -y ${UTILS[@]}
    return $?
}

function apt_install_dependencies() {
    if [ ${#DEPENDENCIES[@]} -eq 0 ]; then
        echo '[ INFO ]: No dependencies to fetch using the apt package manager.'
        return 1
    fi
    echo "[ INFO ]: Installing dependencies using apt package manager:"
    apt_install_dependency ${DEPENDENCIES[@]}
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Failed to install ($SCRIPT_NAME) dependencies!"
    else
        echo "[ OK ]: Successfully installed ($SCRIPT_NAME) dependencies!"
    fi
    return 0
}

# HANDLERS

function handle_actions() {
    declare -A ACTIONS
    local FAILURES=0
    if [[ "${DEFAULT['shred']}" == 'on' ]]; then
        local ACTIONS=(
            ['files']='action_shred_files'
            ['directories']='action_shred_directories'
            ['devices']='action_shred_devices'
        )
    else
        local ACTIONS=(
            ['files']='action_cleanup_files'
            ['directories']='action_cleanup_directories'

        )
    fi
    for cleanup_type in `echo ${DEFAULT['clean-type']} | tr ',' ' '`; do
        case "${cleanup_type}" in
            'files')
                echo "[ INFO ]: Cleaning up files..."
                ;;
            'directories')
                echo "[ INFO ]: Cleaning up directories..."
                ;;
            'devices')
                echo "[ INFO ]: Cleaning up devices..."
                ;;
            *)
                echo "[ WARNING ]: Unsupported cleanup type! (${cleanup_type})"
                local FAILURES=$((FAILURES+1))
                ;;
        esac
        ${ACTIONS[${cleanup_type}]}
        local FAILURES=$((FAILURES+$?))
    done
    return $FAILURES
}

# PROCESSORS

function process_arguments() {
    for opt in $@; do
        case "$opt" in
            -h|--help)
                display_usage
                exit 0
                ;;
            -q|--silent)
                DEFAULT['silent']='on'
                ;;
            --setup)
                if [ $EUID -ne 0 ]; then
                    display_usage
                    echo "[ WARNING ]: --setup requires priviledged access rights!"\
                        "Are you root?"
                    exit 2
                fi
                apt_install_dependencies
                exit $?
                ;;
            -c=*|--clean=*)
                DEFAULT['clean']="${opt#*=}"
                ;;
            -t=*|--clean-type=*)
                DEFAULT['clean-type']="${opt#*=}"
                echo ${DEFAULT['clean-type']} | grep 'devices' &> /dev/null
                if [ $? -eq 0 ]; then
                    DEFAULT['shred']='on'
                    if [ -z "${DEFAULT['clean']}" ]; then
                        DEFAULT['clean']='devices'
                    fi
                fi
                ;;
            -d=*|--directory-regex=*)
                DEFAULT['dir-regex']="${opt#*=}"
                ;;
            -f=*|--file-regex=*)
                DEFAULT['file-regex']="${opt#*=}"
                ;;
            -b=*|--block-device-regex=*)
                DEFAULT['block-device-regex']="${opt#*=}"
                ;;
            -C=*|--cron-locations=*)
                LOCATIONS['cron']="${opt#*=}"
                ;;
            -L=*|--log-locations=*)
                LOCATIONS['log']="${opt#*=}"
                ;;
            -D=*|--device-locations=*)
                LOCATIONS['device']="${opt#*=}"
                ;;
            -H=*|--home-locations=*)
                LOCATIONS['home']="${opt#*=}"
                ;;
            -s|--shred)
                DEFAULT['shred']='on'
                ;;
            -S|--self-destruct)
                DEFAULT['self-destruct']='on'
                ;;
            -p=*|--shredder-patterns=*)
                DEFAULT['shredder-patterns']="${opt#*=}"
                ;;
            -l=*|--locations-file=*)
                if [ -f "${opt#*=}" ]; then
                    DEFAULT['location-file']="${opt#*=}"
                    source "${DEFAULT['location-file']}"
                else
                    echo "[ WARNING ]: No location file found! (${opt#*=})"
                    exit 3
                fi
                ;;
            -P=*|--shredder-passes=*)
                DEFAULT['shredder-passes']=${opt#*=}
                ;;
            -z|--hide-shred)
                DEFAULT['hide-shred']='on'
                ;;
            -e=*|--custom-erasure-pattern=*)
                DEFAULT['custom-pattern']="${opt#*=}"
                ;;
            -B=*|--block-size=*)
                DEFAULT['block-size']=${opt#*=}
                ;;
            *)
                echo "[ WARNING ]: Invalid argument! (${opt})"
                ;;
        esac
    done
    return 0
}

# INIT

function init_self_destruct_sequence() {
    echo "[ WARNING ]: Self destruct sequence initiated!"
    local FILES2REMOVE=
    if [[ "${DEFAULT['nuke']}" == 'on' ]]; then
        local CURRENT_DIRECTORY_PATH="$(
            cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd
        )"
        echo "[   x_X   ]: Nuke target painted! (${CURRENT_DIRECTORY_PATH})"
        local FILES2REMOVE="${CURRENT_DIRECTORY_PATH} ${DEFAULT['location-file']}"
    else
        local CURRENT_FILE_PATH="${BASH_SOURCE[0]}"
        echo "[   T_T   ]: Thats all folks! (${CURRENT_FILE_PATH})"
        local FILES2REMOVE="${CURRENT_FILE_PATH} ${DEFAULT['location-file']}"
    fi
    echo "[   :|    ]: Removing: (${FILES2REMOVE})"
    rm -rf ${FILES2REMOVE} &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[   :(    ]: Could not remove targets! Exit (${EXIT_CODE})"
    else
        echo "[   :>    ]: Squeaky Clean!!"
    fi
    return $EXIT_CODE
}

function init_script() {
    process_arguments $@
    if [ $? -ne 0 ]; then return 1; fi
    display_header
    if [ ! -z "${DEFAULT['clean']}" ]; then
        case "${DEFAULT['silent']}" in
            'on')
                local HANDLER='handle_actions &> /dev/null'
                ;;
            *)
                local HANDLER='handle_actions'
                ;;
        esac
        ${HANDLER}
    fi
    local EXIT_CODE=$?
    if [[ "${DEFAULT['safety']}" == 'off' ]] \
        && [[ "${DEFAULT['self-destruct']}" == 'on' ]]; then
        init_self_destruct_sequence
        local EXIT_CODE=$((EXIT_CODE+$?))
    elif [[ "${DEFAULT['self-destruct']}" == 'on' ]]; then
        msg_safety_warning
        echo '[ NOK ]: Could not initiate self destruct sequence! (T_x)-\'
    fi
    echo "[ DONE ]: ${SCRIPT_NAME}"
    return $EXIT_CODE
}

# MISCELLANEOUS

init_script $@
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "[ EXIT ]: $EXIT_CODE
    "
else
    echo
fi

exit $EXIT_CODE

# CODE DUMP


