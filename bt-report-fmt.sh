#!/bin/bash
#
# Excellent Regards, the Alveare Solutions #!/Society -x
#
# Bullet Tree(T*) - Report Formatter Tool

SKETCH_FILE_PATH="$1"

function display_header() {
    cat <<EOF
    ___________________________________________________________________________

     *               *  Bullet Tree(T) - Report Formatter Tool  *            *
    ___________________________________________________________________________
                     Regards, the Alveare Solutions #!/Society -x

EOF
    return $?
}


function display_usage() {
    display_header
    cat <<EOF
    [ EXAMPLE     ]: ./`basename $0` <SKETCH-FILE-PATH>

    [ SKETCH FILE ]: <LEVEL>:<LINX-LVL-CSV>:<MESSAGE>;

         0:-:Level 0;     |              |   * Level 0
         1:0:Level 1;     |              |   |__ * Level 1
         2:0:Level 2;     |              |   |   |__ * Level 2
         3:0:Level 3;     |              |   |       |__ * Level 3
         4:0:Level 4;     |              |   |           |__ * Level 4
         5:0:Level 5;     |              |   |               |__ * Level 5
         1:-:Level 1;     |              |   |
         2:-:Level 2;     |              |   |__ * Level 1
         3:-:Level 3;     |              |       |__ * Level 2
         3:-:Level 3;     |              |           |__ * Level 3
         3:-:Level 3;  ---|---->(TO)-----|-->        |__ * Level 3
         3:-:Level 3;     |              |           |__ * Level 3
         4:2:Level 4;     |              |           |__ * Level 3
         4:2:Level 4;     |              |           |   |__ * Level 4
         5:2,3:Level 5;   |              |           |   |__ * Level 4
         5:2,3:Level 5;   |              |           |   |   |__ * Level 5
         4:2:Level 4;     |              |           |   |   |__ * Level 5
         4:2:Level 4;     |              |           |   |
         3:-:Level 3;     |              |           |   |__ * Level 4
         3:-:Level 3;     |              |           |   |__ * Level 4
                                         |           |
                                         |           |__ * Level 3
                                         |           |__ * Level 3
EOF
    return $?
}

function check_item_in_set() {
    local ITEM="$1"
    local ITEM_SET=( ${@:2} )
    for item in ${ITEM_SET[@]}; do
        if [[ "$item" != "$ITEM" ]]; then
            continue
        fi
        return 0
    done
    return 1
}

function println_on_level() {
    local LEVEL="${1:-0}"
    local LEVEL_LINX="${2:--}"
    local MSG="${@:3}"
    local INCREMENT="    "
    local INCREMENT_LEN=`echo -n "${INCREMENT}" | wc -c`
    local PREFIX=""
    if [[ "$LEVEL" != "0" ]] && [[ "$LEVEL" != "-" ]]; then
        local PREFIX="|__ * "
    elif [[ "$LEVEL" == '0' ]]; then
        local PREFIX="* "
    fi
    if [[ "$LEVEL" != "1" ]] && [[ "$LEVEL" != "0" ]] && [[ "$LEVEL" != "-" ]]; then
        local LEVEL=$((LEVEL - 1))
        for lvl in `seq $LEVEL`; do
            local PREFIX="${INCREMENT}${PREFIX}"
        done
    fi
    if [[ "$LEVEL_LINX" != '-' ]]; then
        local LEVEL_LINX=( `echo "$LEVEL_LINX" | tr ',' ' '` )
        if [ -z "${PREFIX}" ]; then
            local HIGHEST_LINX_LVL=0
            for lnx_lvl in ${LEVEL_LINX[@]}; do
                if [[ ! lnx_lvl -gt ${HIGHEST_LINX_LVL} ]]; then
                    continue
                fi
                local HIGHEST_LINX_LVL=${lnx_lvl}
            done
            for item in `seq ${HIGHEST_LINX_LVL}`; do
                local PREFIX="${INCREMENT}${PREFIX}"
            done
        fi
        for lnx_lvl in ${LEVEL_LINX[@]}; do
            local LINK_INDEX=`echo "$lnx_lvl * $INCREMENT_LEN" | bc`
            local LSLICE="${PREFIX:0:${LINK_INDEX}}"
            local RSLICE="${PREFIX:${LINK_INDEX}}"
            local PREFIX="${LSLICE}|${RSLICE:1}"
        done
    fi
    if [[ "${LEVEL}" == '-' ]]; then
        echo "${PREFIX}"
    else
        echo "${PREFIX}${MSG}"
    fi
    return $?
}

function process_sketch_file_content() {
    local SKETCH_CONTENT="$@"
    local LINE_NO=`echo "$SKETCH_CONTENT" | wc -l`
    local PREVIOUS_LEVEL=0
    local PREVIOUS_LINX=0
    for line_no in `seq $LINE_NO`; do
        local SKETCH_LINE="`echo ${SKETCH_CONTENT} | cut -d ';' -f ${line_no}`"
        local LEVEL=`echo ${SKETCH_LINE} | cut -d ':' -f 1`
        local LINX="`echo ${SKETCH_LINE} | cut -d ':' -f 2`"
        local MSG="`echo ${SKETCH_LINE} | cut -d ':' -f 3`"
        if [ ${LEVEL} -lt ${PREVIOUS_LEVEL} ]; then
            println_on_level - "${PREVIOUS_LINX}"
        fi
        println_on_level ${LEVEL} "${LINX}" "${MSG}"
        local PREVIOUS_LEVEL=${LEVEL}
        local PREVIOUS_LINX="${LINX}"
    done
}

function process_sketch() {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ] || [ -z "${FILE_PATH}" ] || [ -z "`cat ${FILE_PATH}`" ]; then
        return 1
    fi
    local CONTENT="`cat ${FILE_PATH}`"
    process_sketch_file_content "$CONTENT"
    return $?
}

# MISCELLANEOUS

if [ -z "$SKETCH_FILE_PATH" ] || [[ "$SKETCH_FILE_PATH" == "--help" ]]; then
    display_usage
    exit 1
fi

process_sketch "${SKETCH_FILE_PATH}"
exit $?

