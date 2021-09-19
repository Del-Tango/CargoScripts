#!/bin/bash
#
# Regards, the Alveare Solutions society
#
# Hyper Intel

# COLD PARAMETERS

declare -A HI_DEFAULT

SCRIPT_NAME='HyperIntel'
VERSION='AlgoDox'
VERSION_NO='1.0'

HI_DEFAULT=(
['dta-dir']='data'
['procedure-dir']="procedures"
['procedure-index']='hi-procedures.index'
['hintel-index']='hi-hintel.index'
['lintel-index']='hi-lintel.index'
['editor']='vim'
)
HI_DEPENDENCIES=(
'bc'
'test'
)

# HOT PARAMETERS

HI_ACTION=                  # (create | remove | edit | move | merge | link | find | display)
HI_FIND='text'              # (text | path)
HI_PROCEDURE=               # procedure-name
HI_HIGH_LEVEL_INSTRUCTION=  # high-level-instruction-name
HI_LOW_LEVEL_INSTRUCTION=   # low-level-instruction-name
HI_SOURCE=                  # source-path
HI_TARGET=                  # target-path
HI_PRIORITY=0               # numeric priority (0 - highest priority)
HI_STATUS='New'             # (custom status)
HI_FORCE=0                  # (0 | 1)

# FETCHERS

# SETTERS

function set_action () {
    local ACTION="$1"
    if [ -z "$ACTION" ]; then
        return 1
    fi
    HI_ACTION="$ACTION"
    return 0
}

function set_find () {
    local FIND="${1:-text}"
    HI_FIND="$FIND"
    return 0
}

function set_priority () {
    local PRIORITY=$1
    check_value_is_number $PRIORITY
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Priority must be a number, not ($PRIORITY)"
        return 1
    fi
    HI_PRIORITY=$PRIORITY
    return 0
}

# CHECKERS

function check_util_installed () {
    local UTIL="$1"
    which "$UTIL" &> /dev/null
    return $?
}

function check_value_is_number () {
    local VALUE=$1
    if [ ! $VALUE -eq $VALUE ]; then
        return 1
    fi
    return 0
}

function check_root () {
    if [ $EUID -ne 0 ]; then
        return 1
    fi
    return 0
}

# FORMATTERS

function scaffold_procedure_index_content () {
    local TARGET_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    cat<<EOF
# Name: ${HI_DEFAULT['procedure-index']}
# Create Date: `date +'%d-%m-%Y %T'`
# Write Date: `date +'%d-%m-%Y %T'`
# Procedures: $((`cd "$TARGET_DIR" && find . -type d | awk -F/ '{print $2}' | \
                    sort -u | sed '/^$/d' | wc -l && cd - &> /dev/null` - 1))

- Add your comments below -

- Subcomponent Table - PRIORITY,NAME,HINTEL_COUNT,STATUS,WDATE,CDATE -"

EOF
    return $?
}

function scaffold_hintel_index_content () {
    cat<<EOF
# Name: $HI_PROCEDURE
# Status: $HI_STATUS
# Priority: $HI_PRIORITY
# Links:
# Create Date: `date +'%d-%m-%Y %T'`
# Write Date: `date +'%d-%m-%Y %T'`
# High Level Instructions: 0

- Add your comments below -

- Subcomponent Table - PRIORITY,NAME,LINTEL_COUNT,STATUS,WDATE,CDATE -"

EOF
    return $?
}

function scaffold_lintel_index_content () {
    cat<<EOF
# Name: $HI_HIGH_LEVEL_INSTRUCTION
# Procedure: $HI_PROCEDURE
# Status: $HI_STATUS
# Priority: $HI_PRIORITY
# Links:
# Create Date: `date +'%d-%m-%Y %T'`
# Write Date: `date +'%d-%m-%Y %T'`
# Low Level Instructions: 0

- Add your comments below -

- Subcomponent Table - PRIORITY,NAME,STATUS,WDATE,CDATE -

EOF
    return $?
}

function scaffold_lintel_component_content () {
    cat<<EOF
# Name: $HI_LOW_LEVEL_INSTRUCTION
# High Level Instruction: $HI_HIGH_LEVEL_INSTRUCTION
# Procedure: $HI_PROCEDURE
# Status: $HI_STATUS
# Priority: $HI_PRIORITY
# Links:
# Create Date: `date +'%d-%m-%Y %T'`
# Write Date: `date +'%d-%m-%Y %T'`

- Add your comments below -

EOF
    return $?
}

# CREATORS

# UPDATERS

function update_index_tree () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${PROCEDURE}"
    if [ -z "$PROC_DIR" ]; then
        return 1
    fi
    for dir_name in `cd $PROC_DIR && find . -type d | awk -F/ '{print $2}' | \
            sort -u | sed '/^$/d' && cd - &> /dev/null`; do
        local PROCEDURE_PATH="${PROC_DIR}/${dir_name}"
        for hintel_name in `cd $PROCEDURE_PATH && find . -type d | awk -F/ '{print $2}' | sort -u | sed '/^$/d' && cd - &> /dev/null`; do
            local HINTEL_PATH="${PROCEDURE_PATH}/${hintel_name}"
            update_low_level_instruction_index "$dir_name" "$hintel_name"
        done
        update_high_level_instruction_index "$dir_name"
    done
    update_procedure_index
    return 0
}

function update_low_level_instruction_index () {
    local PROCEDURE="$1"
    local HINTEL_INSTRUCTION="$2"
    if [ -z "$PROCEDURE" ] || [ -z "$HINTEL_INSTRUCTION" ]; then
        return 1
    fi
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${PROCEDURE}"
    local HINTEL_DIR="${PROC_DIR}/${HINTEL_INSTRUCTION}"
    local LINTEL_INDEX="${HINTEL_DIR}/${HI_DEFAULT['lintel-index']}"
    local LINTELS=(
        `cd $HINTEL_DIR && find . -type f | awk -F/ '{print $2}' | sort -u | \
         grep -v "${HI_DEFAULT['lintel-index']}" | sed '/^$/d' && cd - &> /dev/null`
    )
    local LINTEL_COUNT=${#LINTELS[@]}
    local WDATE=`date +'%d-%m0%Y %T'`
    local LINE_NO=`cat -n "$LINTEL_INDEX" | grep 'Write Date:' | awk '{print $1}'`
    replace_line_in_file "$LINTEL_INDEX" $LINE_NO "# Write Date: $WDATE"
    local LINE_NO=`cat -n "$LINTEL_INDEX" | grep 'Low Level Instructions:' | awk '{print $1}'`
    replace_line_in_file "$LINTEL_INDEX" $LINE_NO "# Low Level Instructions: $LINTEL_COUNT"
    sed -i '/^*/d' "$LINTEL_INDEX"
    for fl_name in ${LINTELS[@]}; do
        extract_lintel_meta_for_index "${HINTEL_DIR}/${fl_name}" >> "$LINTEL_INDEX"
    done
    return 0
}

function update_high_level_instruction_index () {
    local PROCEDURE="$1"
    if [ -z "$PROCEDURE" ]; then
        return 1
    fi
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${PROCEDURE}"
    local HINTEL_INDEX="${PROC_DIR}/${HI_DEFAULT['hintel-index']}"
    local HINTELS=(
        `cd $PROC_DIR && find . -type d | awk -F/ '{print $2}' | \
         sort -u | sed '/^$/d' && cd - &> /dev/null`
    )
    local WDATE=`date +'%d-%m-%Y %T'`
    local HINTEL_COUNT=${#HINTELS[@]}
    local LINE_NO=`cat -n "$HINTEL_INDEX" | grep 'Write Date:' | awk '{print $1}'`
    replace_line_in_file "$HINTEL_INDEX" $LINE_NO "# Write Date: $WDATE"
    local LINE_NO=`cat -n "$HINTEL_INDEX" | grep 'High Level Instructions:' | awk '{print $1}'`
    replace_line_in_file "$HINTEL_INDEX" $LINE_NO "# High Level Instructions: $HINTEL_COUNT"
    sed -i '/^*/d' "$HINTEL_INDEX"
    for dir_name in ${HINTELS[@]}; do
        local LINTEL_INDEX="${PROC_DIR}/${dir_name}/${HI_DEFAULT['lintel-index']}"
        extract_hintel_meta_for_index "$LINTEL_INDEX" >> "$HINTEL_INDEX"
    done
    return 0
}

function update_procedure_index () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local PROC_ROOT_INDEX="${PROC_DIR}/${HI_DEFAULT['procedure-index']}"
    local PROCEDURES=(
        `cd $PROC_DIR && find . -type d | awk -F/ '{print $2}' | \
         sort -u | sed '/^$/d' && cd - &> /dev/null`
    )
    local WDATE=`date +'%d-%m-%Y %T'`
    local PROCEDURE_COUNT=${#PROCEDURES[@]}
    local LINE_NO=`cat -n "$PROC_ROOT_INDEX" | grep 'Write Date:' | awk '{print $1}'`
    replace_line_in_file "$PROC_ROOT_INDEX" $LINE_NO "# Write Date: $WDATE"
    local LINE_NO=`cat -n "$PROC_ROOT_INDEX" | grep 'Procedures:' | awk '{print $1}'`
    replace_line_in_file "$PROC_ROOT_INDEX" $LINE_NO "# Procedures: $PROCEDURE_COUNT"
    sed -i '/^*/d' $PROC_ROOT_INDEX
    for dir_name in ${PROCEDURES[@]}; do
        local HINTEL_INDEX_PATH="${PROC_DIR}/${dir_name}/${HI_DEFAULT['hintel-index']}"
        extract_procedure_meta_for_index "$HINTEL_INDEX_PATH" >> "$PROC_ROOT_INDEX"
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not extract high level instruction metadata to build root index record!"
        fi
    done
    return 0
}

# ACTIONS

# TODO
function action_import () {
    echo "[ WARNING ]: Under construction, building..."
    return 0
}
function action_move () {
    echo "[ WARNING ]: Under construction, building..."
    return 0
}
function action_merge () {
    echo "[ WARNING ]: Under construction, building..."
    return 0
}

function action_edit () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    if [ ! -z "$HI_STATUS" ] && [ "$HI_STATUS" != 'New' ]; then
        action_edit_status
    elif [ ! -z "$HI_TARGET" ]; then
        action_edit_target
    elif [ ! -z "$HI_LOW_LEVEL_INSTRUCTION" ]; then
        action_edit_lintel_component
    elif [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ]; then
        action_edit_lintel_index
    elif [ ! -z "$HI_PROCEDURE" ]; then
        action_edit_hintel_index
    else
        action_edit_procedure_index
    fi
    update_low_level_instruction_index "$HI_PROCEDURE" "$HI_HIGH_LEVEL_INSTRUCTION" &> /dev/null
    update_high_level_instruction_index "$HI_PROCEDURE" &> /dev/null
    update_procedure_index &> /dev/null
    return $?
}

function action_remove_low_level_instruction () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local LINTEL_FILE="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_LOW_LEVEL_INSTRUCTION}"
    if [ ! -f "$LINTEL_FILE" ]; then
        echo "[ NOK ]: Low level instruction not found! ($HI_LOW_LEVEL_INSTRUCTION)"
        return 1
    else
        remove_file "$LINTEL_FILE"
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not remove file! ($LINTEL_FILE)"
            return 2
        else
            echo "[ OK ]: Low level instruction removed! (${HI_LOW_LEVEL_INSTRUCTION})"
        fi
    fi
    return 0
}

function action_remove_high_level_instruction () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    if [ ! -d "${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}" ]; then
        echo "[ NOK ]: High level instruction not found! ($HI_HIGH_LEVEL_INSTRUCTION)"
        return 1
    else
        remove_directory "${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}"
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not remove directory! (${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION})"
            return 2
        else
            echo "[ OK ]: High level instruction removed! (${HI_HIGH_LEVEL_INSTRUCTION})"
        fi
    fi
    return 0
}

function action_remove_procedure () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    if [ ! -d "${PROC_DIR}/${HI_PROCEDURE}" ]; then
        echo "[ NOK ]: Procedure not found! ($HI_PROCEDURE)"
    else
        remove_directory "${PROC_DIR}/${HI_PROCEDURE}"
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not remove directory! (${PROC_DIR}/${HI_PROCEDURE})"
        else
            echo "[ OK ]: Procedure removed! ($HI_PROCEDURE)"
        fi
    fi
    return 0
}

function action_remove () {
    if [ ! -z "$HI_LOW_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_PROCEDURE" ]; then
        action_remove_low_level_instruction
        update_low_level_instruction_index "$HI_PROCEDURE" "$HI_HIGH_LEVEL_INSTRUCTION"
        update_high_level_instruction_index "$HI_PROCEDURE"
    elif [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_PROCEDURE" ]; then
        action_remove_high_level_instruction
        update_high_level_instruction_index "$HI_PROCEDURE"
    elif [ ! -z "$HI_PROCEDURE" ]; then
        action_remove_procedure
    else
        echo "[ ERROR ]: Invalid remove instruction!"
        return 1
    fi
    update_procedure_index
    return $?
}

function action_link () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    if [ -z "$HI_TARGET" ] || [ -z "$HI_SOURCE" ] \
            && [ ! -e "${PROC_DIR}/${HI_TARGET}" ] \
            || [ ! -e "${PROC_DIR}/${HI_SOURCE}" ]; then
        echo "[ NOK ]: Invalid link instruction! ($HI_SOURCE -> $HI_TARGET)"
        return 1
    fi

    local OLD_SRC_FILE_LINKS=`extract_links ${PROC_DIR}/${HI_SOURCE}`
    local SRC_FILE_LINKS=`echo "$OLD_SRC_FILE_LINKS" | xargs | sed -e 's/^@//' -e 's/@$//' -e 's/ //g'`
    echo "$SRC_FILE_LINKS" | grep "${HI_TARGET}" &> /dev/null
    if [ $? -ne 0 ]; then
        if [ `echo "$OLD_SRC_FILE_LINKS" | wc -c` -ne 1 ]; then
            local FORMATTED="@${HI_TARGET}"
        else
            local FORMATTED="${HI_TARGET}"
        fi
        local SRC_FILE_LINKS=`echo "${OLD_SRC_FILE_LINKS}${FORMATTED}" | sed 's/ //g'`
    fi

    local OLD_DST_FILE_LINKS=`extract_links ${PROC_DIR}/${HI_TARGET}`
    local DST_FILE_LINKS=`echo "$OLD_DST_FILE_LINKS" | xargs | sed -e 's/^@//' -e 's/@$//' -e 's/ //g'`
    echo "$DST_FILE_LINKS" | grep "${HI_SOURCE}" &> /dev/null
    if [ $? -ne 0 ]; then
        if [ `echo "$OLD_DST_FILE_LINKS" | wc -c` -ne 1 ]; then
            local FORMATTED="@${HI_SOURCE}"
        else
            local FORMATTED="${HI_SOURCE}"
        fi
        local DST_FILE_LINKS=`echo "${OLD_DST_FILE_LINKS}${FORMATTED}" | sed 's/ //g'`
    fi

    local SRC_LINE_NO=`cat -n "${PROC_DIR}/${HI_SOURCE}" | grep 'Links:' | awk '{print $1}'`
    replace_line_in_file "${PROC_DIR}/${HI_SOURCE}" $SRC_LINE_NO "# Links: $SRC_FILE_LINKS"
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not set link to source file! ($HI_SOURCE)"
        return 1
    fi

    local DST_LINE_NO=`cat -n "${PROC_DIR}/${HI_TARGET}" | grep 'Links:' | awk '{print $1}'`
    replace_line_in_file "${PROC_DIR}/${HI_TARGET}" $DST_LINE_NO "# Links: $DST_FILE_LINKS"
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not set link to target_file! ($HI_TARGET)"
        replace_line_in_file "${PROC_DIR}/${HI_SOURCE}" $SRC_LINK_NO "# Links: $OLD_SRC_FILE_LINKS"
        return 2
    fi

    update_index_tree
    echo "[ OK ]: Successfully linked components! (${HI_SOURCE} -> ${HI_TARGET})"
    return 0
}

function action_find_text () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local TARGET_PATH=
    local EXIT_CODE=1
    if [ -z "$HI_PROCEDURE" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_DEFAULT['procedure-index']}"
    elif [ -z "$HI_HIGH_LEVEL_INSTRUCTION" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_DEFAULT['hintel-index']}"
    elif [ -z "$HI_LOW_LEVEL_INSTRUCTION" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_DEFAULT['lintel-index']}"
    else
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_LOW_LEVEL_INSTRUCTION}"
    fi
    if [ -e "$TARGET_PATH" ]; then
        local EXIT_CODE=0
    else
        local EXIT_CODE=1
    fi
    case "$EXIT_CODE" in
        "1")
            echo "[ NOK ]: Nothing to see here! ($TARGET_PATH)"
            ;;
        "0")
            local SANITIZED_PATH=`echo $TARGET_PATH | sed 's@//@/@g'`
            echo "[ OK ]: $SANITIZED_PATH -
    _______________________________________________________________________________
"
            cat -n $SANITIZED_PATH && echo -n "
    _______________________________________________________________________________
"
            ;;
    esac
    return $EXIT_CODE
}

function action_find_path () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local TARGET_PATH=
    local EXIT_CODE=1
    if [ -z "$HI_PROCEDURE" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_DEFAULT['procedure-index']}"
    elif [ -z "$HI_HIGH_LEVEL_INSTRUCTION" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_DEFAULT['hintel-index']}"
    elif [ -z "$HI_LOW_LEVEL_INSTRUCTION" ]; then
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_DEFAULT['lintel-index']}"
    else
        local TARGET_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_LOW_LEVEL_INSTRUCTION}"
    fi
    if [ -e "$TARGET_PATH" ]; then
        local EXIT_CODE=0
    else
        local EXIT_CODE=1
    fi
    case "$EXIT_CODE" in
        "1")
            echo "[ NOK ]: Nothing to see here! ($TARGET_PATH)"
            ;;
        "0")
            echo "[ OK ]: Path: $TARGET_PATH" | sed -e 's@//@/@g'
            ;;
    esac
    return $EXIT_CODE
}

function action_find () {
    case "$HI_FIND" in
        'text')
            action_find_text
            ;;
        'path')
            action_find_path
            ;;
        *)
            echo "[ ERROR ]: Invalid find instruction! ($HI_FIND)"
            return 1
            ;;
    esac
    return $?
}

function action_edit_lintel_component () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local COMPONENT_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_LOW_LEVEL_INSTRUCTION}"
    if [ ! -f "$COMPONENT_PATH" ]; then
        echo "[ NOK ]: Low level instruction component file does not exist! ($COMPONENT_PATH)"
        return 1
    fi
    ${HI_DEFAULT['editor']} $COMPONENT_PATH
    return $?
}

function action_edit_lintel_index () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local INDEX_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_DEFAULT['lintel-index']}"
    if [ ! -f "$INDEX_PATH" ]; then
        echo "[ NOK ]: Low level instruction index file does not exist! ($INDEX_PATH)"
        return 1
    fi
    ${HI_DEFAULT['editor']} $INDEX_PATH
    return $?
}

function action_edit_hintel_index () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local INDEX_PATH="${PROC_DIR}/${HI_PROCEDURE}/${HI_DEFAULT['hintel-index']}"
    if [ ! -f "$INDEX_PATH" ]; then
        echo "[ NOK ]: High level instruction index file does not exist! ($INDEX_PATH)"
        return 1
    fi
    ${HI_DEFAULT['editor']} $INDEX_PATH
    return $?
}

function action_edit_procedure_index () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local INDEX_PATH="${PROC_DIR}/${HI_DEFAULT['procedure-index']}"
    if [ ! -f "$INDEX_PATH" ]; then
        echo "[ NOK ]: Procedure index file does not exist! ($INDEX_PATH)"
        return 1
    fi
    ${HI_DEFAULT['editor']} $INDEX_PATH
    return $?
}

function action_edit_status () {
    local EXIT_CODE=1
    if [ ! -z "$HI_LOW_LEVEL_INSTRUCTION" ]; then
        local FILE_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_LOW_LEVEL_INSTRUCTION}"
        local LINE_NO=`cat -n $FILE_PATH | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "$FILE_PATH" $LINE_NO "# Status: $HI_STATUS"
        local EXIT_CODE=$?
    elif [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ]; then
        local FILE_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}/${HI_HIGH_LEVEL_INSTRUCTION}/${HI_DEFAULT['lintel-index']}"
        local LINE_NO=`cat -n $FILE_PATH | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "$FILE_PATH" $LINE_NO "# Status: $HI_STATUS"
        local EXIT_CODE=$?
        waterfall_lintel_index_status "$FILE_PATH"
    elif [ ! -z "$HI_PROCEDURE" ]; then
        local FILE_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}/${HI_DEFAULT['hintel-index']}"
        local LINE_NO=`cat -n $FILE_PATH | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "$FILE_PATH" $LINE_NO "# Status: $HI_STATUS"
        local EXIT_CODE=$?
        waterfall_hintel_index_status "$FILE_PATH"
    else
        local FILE_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_DEFAULT['procedure-index']}"
        local LINE_NO=`cat -n $FILE_PATH | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "$FILE_PATH" $LINE_NO "# Status: $HI_STATUS"
        local EXIT_CODE=$?
        waterfall_root_index_status "$FILE_PATH"
    fi
    if [ $? -ne 0 ] || [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not edit component status! ($HI_STATUS)"
    else
        echo "[ OK ]: Status modified! ($HI_STATUS)"
    fi
    return $EXIT_CODE
}

function action_edit_target () {
    if [ ! -f "${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_TARGET}" ]; then
        echo "[ WARNING ]: Target not found! ($HI_TARGET)"
        return 1
    fi
    ${HI_DEFAULT['editor']} "${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_TARGET}"
    return $?
}

function action_create_low_level_instruction () {
    local PROCEDURE_DIR_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}"
    if [ ! -d "$PROCEDURE_DIR_PATH" ]; then
        action_create_procedure
    fi
    local NEW_HINTEL_DIR_PATH="${PROCEDURE_DIR_PATH}/${HI_HIGH_LEVEL_INSTRUCTION}"
    if [ ! -d "" ]; then
        action_create_high_level_instruction
    fi
    local NEW_LINTEL_FILE_PATH="${NEW_HINTEL_DIR_PATH}/${HI_LOW_LEVEL_INSTRUCTION}"
    if [ -f "$NEW_LINTEL_FILE_PATH" ]; then
        echo "[ NOK ]: Low level instruction already exists! ($NEW_LINTEL_FILE_PATH)"
        return 1
    fi
    scaffold_lintel_component_content > "$NEW_LINTEL_FILE_PATH"
    update_low_level_instruction_index "$HI_PROCEDURE" "$HI_HIGH_LEVEL_INSTRUCTION"
    update_high_level_instruction_index "$HI_PROCEDURE"
    update_procedure_index
    return 0
}

function action_create_high_level_instruction () {
    local PROCEDURE_DIR_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}"
    if [ ! -d "$PROCEDURE_DIR_PATH" ]; then
        action_create_procedure
    fi
    local NEW_HINTEL_DIR_PATH="${PROCEDURE_DIR_PATH}/${HI_HIGH_LEVEL_INSTRUCTION}"
    mkdir -p "$NEW_HINTEL_DIR_PATH" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not create new high level instruction! ($NEW_HINTEL_DIR_PATH)"
        return 1
    else
        echo "[ OK ]: High level instruction directory ($NEW_HINTEL_DIR_PATH)"
    fi
    local NEW_LINTEL_PATH="${NEW_HINTEL_DIR_PATH}/${HI_DEFAULT['lintel-index']}"
    touch "$NEW_LINTEL_PATH" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not create new low level instruction index! ($NEW_LINTEL_PATH)"
        return 2
    else
        echo "[ OK ]: Low level instruction index ($NEW_LINTEL_PATH)"
    fi
    scaffold_lintel_index_content > "$NEW_LINTEL_PATH"
    update_low_level_instruction_index "$HI_PROCEDURE" "$HI_HIGH_LEVEL_INSTRUCTION"
    update_high_level_instruction_index "$HI_PROCEDURE"
    update_procedure_index
    return 0
}

function action_create_procedure () {
    local NEW_PROCEDURE_DIR_PATH="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_PROCEDURE}"
    mkdir -p "$NEW_PROCEDURE_DIR_PATH" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not create new procedure! ($HI_PROCEDURE)"
    else
        echo "[ OK ]: Procedure directory! ($NEW_PROCEDURE_DIR_PATH)"
    fi
    local NEW_HINTEL_INDEX_PATH="${NEW_PROCEDURE_DIR_PATH}/${HI_DEFAULT['hintel-index']}"
    scaffold_hintel_index_content > "$NEW_HINTEL_INDEX_PATH"
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not create new high level instruction index! ($NEW_HINTEL_INDEX_PATH)"
    else
        echo "[ OK ]: New high level instruction index! ($NEW_HINTEL_INDEX_PATH)"
    fi
    update_procedure_index
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not update root procedure index!"
    else
        echo "[ OK ]: Successfully updated root procedure index!"
    fi
    return 0
}

function action_create () {
    if [ ! -z "$HI_LOW_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_PROCEDURE" ]; then
        action_create_low_level_instruction
    elif [ ! -z "$HI_HIGH_LEVEL_INSTRUCTION" ] \
            && [ ! -z "$HI_PROCEDURE" ]; then
        action_create_high_level_instruction
    elif [ ! -z "$HI_PROCEDURE" ]; then
        action_create_procedure
    else
        echo "[ ERROR ]: Invalid create instruction!"
        return 1
    fi
    return $?
}

function action_display () {
    display_procedure_table
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not display $SCRIPT_NAME procedures!"
        return 1
    fi
    return 0
}

# HANDLERS

function handle_action () {
    case "$HI_ACTION" in
        'create')
            action_create
            ;;
        'remove')
            action_remove
            ;;
        'edit')
            action_edit
            ;;
        'move')
            action_move
            ;;
        'merge')
            action_merge
            ;;
        'link')
            action_link
            ;;
        'find')
            action_find
            ;;
        'display')
            action_display
            ;;
        *)
            echo "[ WARNING ]: Invalid action! ($HI_ACTION)"
            return 1
            ;;
    esac
    return $?
}

# GENERAL

function remove_directory () {
    local DIR_PATH="$1"
    if [ $HI_FORCE -eq 1 ]; then
        rm -rf "$DIR_PATH" &> /dev/null
    else
        rm -ri "$DIR_PATH"
    fi
    return $?
}

function remove_file () {
    local FL_PATH="$1"
    if [ $HI_FORCE -eq 1 ]; then
        rm -rf "$FL_PATH" &> /dev/null
    else
        rm -ri "$FL_PATH"
    fi
    return $?
}

function waterfall_lintel_index_status () {
    local LINTEL_INDEX_PATH="$1"
    local LINTEL_DIR=`dirname $LINTEL_INDEX_PATH`
    local INDEX_STATUS=`extract_status "$LINTEL_INDEX_PATH"`
    local LINTELS=(
        `cd $LINTEL_DIR && find . -type f | awk -F/ '{print $2}' | sort -u | \
         grep -v "${HI_DEFAULT['lintel-index']}" && cd - &> /dev/null`
    )
    for fl_name in ${LINTELS[@]}; do
        local LINE_NO=`cat -n ${LINTEL_DIR}/${fl_name} | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "${LINTEL_DIR}/${fl_name}" $LINE_NO "# Status: $INDEX_STATUS"
    done
    return 0
}

function waterfall_hintel_index_status () {
    local HINTEL_INDEX_PATH="$1"
    local HINTEL_DIR=`dirname $HINTEL_INDEX_PATH`
    local INDEX_STATUS=`extract_status "$HINTEL_INDEX_PATH"`
    local HINTELS=(
        `cd $HINTEL_DIR && find . -type d | awk -F/ '{print $2}' | sort -u \
         && cd - &> /dev/null`
    )
    for dir_name in ${HINTELS[@]}; do
        local LINTEL_INDEX_PATH="${HINTEL_DIR}/${dir_name}/${HI_DEFAULT['lintel-index']}"
        local LINE_NO=`cat -n ${LINTEL_INDEX_PATH} | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "${LINTEL_INDEX_PATH}" $LINE_NO "# Status: $INDEX_STATUS"
    done
    return 0
}

function waterfall_root_index_status () {
    local PROCEDURE_INDEX_PATH="$1"
    local PROCEDURE_DIR=`dirname $PROCEDURE_INDEX_PATH`
    local INDEX_STATUS=`extract_status "$PROCEDURE_INDEX_PATH"`
    local PROCEDURES=(
        `cd $PROCEDURE_DIR && find . -type d | awk -F/ '{print $2}' | sort -u | \
            sed '/^$/d' && cd - &> /dev/null`
    )
    for dir_name in ${PROCEDURES[@]}; do
        local HINTEL_INDEX_PATH="${PROCEDURE_DIR}/${dir_name}/${HI_DEFAULT['hintel-index']}"
        local LINE_NO=`cat -n ${HINTEL_INDEX_PATH} | grep 'Status:' | awk '{print $1}'`
        replace_line_in_file "${HINTEL_INDEX_PATH}" $LINE_NO "# Status: $INDEX_STATUS"
    done
    return 0
}

function extract_lintel_meta_for_index () {
    local LINTEL_COMPONENT="$1"
    local NAME=`extract_name "$LINTEL_COMPONENT"`
    local STATUS=`extract_status "$LINTEL_COMPONENT"`
    local PRIORITY=`extract_priority "$LINTEL_COMPONENT"`
    local LINKS=`extract_links "$LINTEL_COMPONENT"`
    local CDATE=`extract_create_date "$LINTEL_COMPONENT"`
    local WDATE=`extract_write_date "$LINTEL_COMPONENT"`
    if [ ! -z "$LINKS" ]; then
        local NAME="${NAME}->`echo ${LINKS} | sed 's/ //g'`"
    fi
    local INDEX_RECORD="* ${PRIORITY:-$HI_PRIORITY},${NAME},${STATUS:-$HI_STATUS},${WDATE},${CDATE}"
    echo "$INDEX_RECORD" | sed -e 's/, /,/g' -e 's/ ,/,/g'
    return $?
}

function extract_hintel_meta_for_index () {
    local LINTEL_INDEX="$1"
    local NAME=`extract_name "$LINTEL_INDEX"`
    local PROCEDURE=`extract_procedure "$LINTEL_INDEX"`
    local STATUS=`extract_status "$LINTEL_INDEX"`
    local PRIORITY=`extract_priority "$LINTEL_INDEX"`
    local LINKS=`extract_links "$LINTEL_INDEX"`
    local CDATE=`extract_create_date "$LINTEL_INDEX"`
    local WDATE=`extract_write_date "$LINTEL_INDEX"`
    local LINTEL_COUNT=`extract_lintel_count "$LINTEL_INDEX"`
    if [ ! -z "$LINKS" ]; then
        local NAME="${NAME}->`echo ${LINKS} | sed 's/ //g'`"
    fi
    local INDEX_RECORD="* ${PRIORITY:-$HI_PRIORITY},${NAME},${LINTEL_COUNT},${STATUS:-$HI_STATUS},${WDATE},${CDATE}"
    echo "$INDEX_RECORD" | sed -e 's/, /,/g' -e 's/ ,/,/g'
    return $?
}

function extract_procedure_meta_for_index () {
    local HINTEL_INDEX="$1"
    local NAME=`extract_name "$HINTEL_INDEX"`
    local STATUS=`extract_status "$HINTEL_INDEX"`
    local PRIORITY=`extract_priority "$HINTEL_INDEX"`
    local LINKS=`extract_links "$HINTEL_INDEX"`
    local CDATE=`extract_create_date "$HINTEL_INDEX"`
    local WDATE=`extract_write_date "$HINTEL_INDEX"`
    local HINTEL_COUNT=`extract_hintel_count "$HINTEL_INDEX"`
    if [ ! -z "$LINKS" ]; then
        local NAME="${NAME}->`echo ${LINKS} | sed 's/ //g'`"
    fi
    local INDEX_RECORD="* ${PRIORITY:-$HI_PRIORITY},${NAME},${HINTEL_COUNT},${STATUS:-$HI_STATUS},${WDATE},${CDATE}"
    echo "$INDEX_RECORD" | sed -e 's/, /,/g' -e 's/ ,/,/g'
    return $?
}

function shred_directory () {
    local TARGET_DIR="$1"
    find "$TARGET_DIR" -type f | xargs shred f -n 10 -z -u &> /dev/null
    rm -rf "$TARGET_DIR" &> /dev/null
    return $?
}

function replace_line_in_file () {
    local FILE_PATH="$1"
    local LINE_NO=$2
    local CONTENT="${@:3}"
    local SED_CMD="${LINE_NO}s|.*|${CONTENT}|"
    sed -i "$SED_CMD" "$FILE_PATH" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ ERROR ]: Failed to update file! (${FILE_PATH}:${LINE_NO})"
        return 1
    fi
    return 0
}

function remove_line_from_file () {
    local LINE_NO=$1
    local FILE_PATH="$2"
    if [ ! -f "$FILE_PATH" ]; then
        echo "[ WARNING ]: File not found! (${FILE_PATH})"
        return 1
    fi
    if [ ! $LINE_NO -eq $LINE_NO &> /dev/null ]; then
        echo "[ WARNING ]: Invalid line number! Number required, not (${LINE_NO})."
        return 2
    fi
    sed -i -e "${LINE_NO}d" "$FILE_PATH" &> /dev/null
    return $?
}

function extract_procedure () {
    local INDEX_FILE="$1"
    local PROCEDURE=`cat $INDEX_FILE | grep '^#' | grep 'Procedure:' | sed 's/# Procedure://'`
    echo "$PROCEDURE"
    return $?
}

function extract_name () {
    local INDEX_FILE="$1"
    local NAME=`cat $INDEX_FILE | grep '^#' | grep 'Name:' | sed 's/# Name://'`
    echo "$NAME"
    return $?
}

function extract_status () {
    local INDEX_FILE="$1"
    local STATUS=`cat $INDEX_FILE | grep '^#' | grep 'Status:' | sed 's/# Status://'`
    echo "$STATUS"
    return 0
}

function extract_priority () {
    local INDEX_FILE="$1"
    local PRIORITY=`cat $INDEX_FILE | grep '^#' | grep 'Priority:' | sed 's/# Priority://'`
    echo $PRIORITY
    return 0
}

function extract_links () {
    local INDEX_FILE="$1"
    local LINKS=`cat $INDEX_FILE | grep '^#' | grep 'Links:' | sed 's/# Links://'`
    echo "$LINKS"
    return 0
}

function extract_create_date () {
    local INDEX_FILE="$1"
    local CDATE=`cat $INDEX_FILE | grep '^#' | grep 'Create Date:' | sed 's/# Create Date://'`
    echo "$CDATE"
    return 0
}

function extract_write_date () {
    local INDEX_FILE="$1"
    local WDATE=`cat $INDEX_FILE | grep '^#' | grep 'Write Date:' | sed 's/# Write Date://'`
    echo "$WDATE"
    return 0
}

function extract_hintel_count () {
    local INDEX_FILE="$1"
    local HINTEL_COUNT=`cat $INDEX_FILE | grep '^#' | grep 'High Level Instructions:' | sed 's/# High Level Instructions://'`
    echo "$HINTEL_COUNT"
    return 0
}

function extract_lintel_count () {
    local INDEX_FILE="$1"
    local LINTEL_COUNT=`cat $INDEX_FILE | grep '^#' | grep 'Low Level Instructions:' | sed 's/# Low Level Instructions://'`
    echo "$LINTEL_COUNT"
    return 0
}

function install_dependencies () {
    check_root
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Dependency install requires superuser privileges. Are you root?"
        return 1
    fi
    for util in ${HI_DEPENDENCIES[@]}; do
        check_util_installed "$util"
        if [ $? -ne 0 ]; then
            echo "[ INFO ]: Installing dependency... ($util)"
        else
            echo "[ OK ]: Dependency ($util) already installed. Skipping."
            continue
        fi
        apt-get install "$util" -y
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not install dependency!"
        else
            echo "[ OK ]: Successfully installed dependency!"
        fi
    done
    return 0
}

# SETUP

function setup_procedure_directory () {
    if [ ! -d "${HI_DEFAULT['dta-dir']}" ] \
            || [ ! -d "${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}" ]; then
        echo "[ INFO ]: Creating procedure directory... (${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']})"
        mkdir -p "${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}" &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not create procedure directory!"
            return 1
        else
            echo "[ OK ]: Successfully created procedure directory!"
        fi
    else
        echo "[ OK ]: Procedure directory already exists. Skipping. (${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']})"
    fi
    return 0
}

function setup_index_files () {
    local PROC_DIR="${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}"
    local ROOT_INDEX="${PROC_DIR}/${HI_DEFAULT['procedure-index']}"
    echo "[ INFO ]: Probing (${ROOT_INDEX})"
    touch "${ROOT_INDEX}"
    if [ ! -f "${ROOT_INDEX}" ] || [ -z "`cat ${ROOT_INDEX}`" ]; then
        scaffold_procedure_index_content > "$ROOT_INDEX"
    fi
    for pdir_name in `cd $PROC_DIR && find . -type d | awk -F/ '{print $2}' | sort -u | sed '/^$/d' && cd - &> /dev/null`; do
        echo "[ INFO ]: Probing (${PROC_DIR}/${pdir_name}/${HI_DEFAULT['hintel-index']})"
        touch "${PROC_DIR}/${pdir_name}/${HI_DEFAULT['hintel-index']}" &> /dev/null
        local PROCEDURE_PATH="${PROC_DIR}/${pdir_name}"
        for hdir_name in `cd $PROCEDURE_PATH && find . -type d | awk -F/ '{print $2}' | sort -u | sed '/^$/d' && cd - &> /dev/null `; do
            echo "[ INFO ]: Probing (${PROC_DIR}/${pdir_name}/${hdir_name}/${HI_DEFAULT['lintel-index']})"
            touch "${PROC_DIR}/${pdir_name}/${hdir_name}/${HI_DEFAULT['lintel-index']}" &> /dev/null

        done
    done
    return 0
}

function setup_project_structure () {
    setup_procedure_directory
    setup_index_files
    update_procedure_index
    return $?
}

function setup_hyperintel () {
    install_dependencies
    setup_project_structure
    return $?
}

# DISPLAY

function display_procedure_table () {
    update_procedure_index
    cat "${HI_DEFAULT['dta-dir']}/${HI_DEFAULT['procedure-dir']}/${HI_DEFAULT['procedure-index']}"
    return $?
}

function display_header () {
    cat<<EOF
    _______________________________________________________________________________

     *           *           *         ${SCRIPT_NAME}        *           *           *
    ________________________________________________________v.${VERSION_NO}${VERSION}___________
                       Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}

function display_usage () {
    display_header
    local SCRIPT_FILE=`basename $0`
    cat <<EOF
    -h  | --help                Display this message
    -c  | --create              Action create new entity
    -r  | --remove              Action remove existing entity
    -e  | --edit                Action edit entity
    -L  | --link                Action link entity to another of the same kind
    -d  | --display             Display all procedures
    -F  | --force               Skip interactive prompts for action
    -f= | --find=TARGET         Find the file path to an entity or the content of one
    -P= | --priority=NUM        Numeric priority of entity
    -p= | --procedure=NAME      High level procedure label
    -h= | --hintel=NAME         High level instruction label
    -l= | --lintel=NAME         Low level instruction label
    -s= | --source=PATH         Source file path for action
    -t= | --target=PATH         Target file path for action
    -S  | --status=STATUS       Custom component status - Higher level component
                                status waterfalls on all subcomponents
          --setup               Setup project $SCRIPT_NAME v${VERSION_NO}${VERSION}

    [ EXAMPLE ]: ./$SCRIPT_FILE --setup
    [ EXAMPLE ]: ./$SCRIPT_FILE --create --procedure=FirstProcedure \\
                                  --hintel=Story1 --lintel=Task1
    [ EXAMPLE ]: ./$SCRIPT_FILE --edit --target=FirstProcedure/Story1/Task1
    [ EXAMPLE ]: ./$SCRIPT_FILE --edit --procedure=FirstProcedure \\
                                  --hintel=Story1 --lintel=Task1
    [ EXAMPLE ]: ./$SCRIPT_FILE --find='path' --procedure=Story1
    [ EXAMPLE ]: ./$SCRIPT_FILE --find='text' --procedure=Story1 \\
                                  --hintel=AddSupport --lintel=UpgradeLib
EOF
    return $?
}

# INIT

function init_hyperintel () {
    local ARGUMENTS=$@
    if [ -z "$ARGUMENTS" ]; then
        display_usage
        return 1
    fi
    for opt in ${ARGUMENTS}; do
        case "$opt" in
            -h|--help)
                display_usage
                return $?
                ;;
            -c|--create)
                set_action "create"
                ;;
            -r|--remove)
                set_action "remove"
                ;;
            -e|--edit)
                set_action "edit"
                ;;
#           -m|--move)
#               set_action "move"
#               ;;
#           -M|--merge)
#               set_action "merge"
#               ;;
#           -i|--import)
#               set_action "import"
#               ;;
            -L|--link)
                set_action "link"
                ;;
            -d|--display)
                set_action "display"
                ;;
            -F|--force)
                HI_FORCE=1
                ;;
            -f|-f=*|--find|--find=*)
                set_action "find"
                set_find "${opt#*=}"
                ;;
            -P=*|--priority=*)
                set_priority ${opt#*=}
                ;;
            -p=*|--procedure=*)
                HI_PROCEDURE="${opt#*=}"
                ;;
            -h=*|--hintel=*)
                HI_HIGH_LEVEL_INSTRUCTION="${opt#*=}"
                ;;
            -l=*|--lintel=*)
                HI_LOW_LEVEL_INSTRUCTION="${opt#*=}"
                ;;
            -s=*|--source=*)
                HI_SOURCE="${opt#*=}"
                ;;
            -t=*|--target=*)
                HI_TARGET="${opt#*=}"
                ;;
            -s=*|--status=*)
                HI_STATUS="${opt#*=}"
                ;;
            --setup)
                display_header
                setup_hyperintel
                return $?
                ;;
            *)
                echo "[ WARNING ]: Invalid option! ($opt)"
                ;;
        esac
    done
    if [[ "$HI_ACTION" != 'edit' ]]; then
        display_header
    fi
    handle_action
    return $?
}

# MISCELLANEOUS

init_hyperintel $@
exit $?

