#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# GAME CHANGER

SCRIPT_NAME='GameChanger'
VERSION='Shell2C'
VERSION_NO='1.0'
COMPOSE_SHEBANG='#!/bin/bash'
# Compiled binary end of life
EXPIRATION_DATE='' #dd/mm/yyyy
EXPIRATION_MSG="
${BLUE}$SCRIPT_NAME ${RESET}(v.${MAGENTA}${VERSION_NO} ${VERSION}${RESET}) -

License expired on (${RED}${EXPIRATION_DATE}${RESET}).
Please contact your service provider.
"
# Inputs
TARGET_FILE_PATH='untitled.sh'
COMPOSE_FILES=()
COMPOSE_DIRECTORIES=()
# Outputs
OUTPUT_FILE_PATH='untitled'
#COMPOSE_FILE_PATH='untitled.sh'
# Flags
VERBOSE_FLAG='off'
COMPOSE_FLAG='off'
SETUID_FLAG='on'
KEEP_C_SOURCE_CODE_FLAG='off'
DEBUG_EXEC_CALLS_FLAG='off'
RELAX_SECURITY_FLAG='off'
UNTRACEABLE_BINARY_FLAG='on'
HARDENED_BINARY_FLAG='on'
COMPILE_FOR_BUSYBOX_FLAG='off'

# FORMATTERS

function format_shell_to_c_arguments () {
    ARGUMENTS=(
        "-f $TARGET_FILE_PATH"
        "-o $OUTPUT_FILE_PATH"
    )
    if [[ ! -z "$EXPIRATION_DATE" ]]; then
        ARGUMENTS=(
            ${ARGUMENTS[@]}
            "-e $EXPIRATION_DATE"
            "-m $EXPIRATION_MSG"
        )
    fi
    if [[ "$VERBOSE_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-v" )
    fi
    if [[ "$SETUID" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-S" )
    fi
    if [[ "DEBUG_EXEC_CALLS_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-D" )
    fi
    if [[ "RELAX_SECURITY_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-r" )
    fi
    if [[ "UNTRACEABLE_BINARY_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-U" )
    fi
    if [[ "HARDENED_BINARY_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-H" )
    fi
    if [[ "COMPILE_FOR_BUSYBOX_FLAG" == 'on' ]]; then
        ARGUMENTS=( ${ARGUMENTS[@]} "-B" )
    fi
    echo ${ARGUMENTS[@]}
    return $?
}

# GENERAL

function merge_files () {
    local TARGET_PATH=$1
    local SOURCE_PATH=$2
    CONTENT_TAG="# --- Composed from file - $SOURCE_PATH ---"
    CONTENT="`cat "$SOURCE_PATH" | grep -v '#!/'`"
    sed -i "2 s|^|$CONTENT\n|" "$TARGET_PATH" #&> /dev/null
    sed -i "2 s|^|$CONTENT_TAG\n|" "$TARGET_PATH" #&> /dev/null
    return $?
}

function shorten_file_path () {
    local FILE_PATH="$1"
    DIR_PATH=`dirname $FILE_PATH 2> /dev/null`
    DIR_NAME=`basename $DIR_PATH 2> /dev/null`
    FL_NAME=`basename $FILE_PATH 2> /dev/null`
    local FL_SHORT="${DIR_NAME}/${FL_NAME}"
    echo "$FL_SHORT"
    return $?
}

function remove_c_source_file () {
    OUT_DIR="`dirname $OUTPUT_FILE_PATH`/"
    if [[ "$OUT_DIR" == './' ]]; then
        OUT_DIR=''
    fi
    OUT_FL=`basename $TARGET_FILE_PATH`
    C_SOURCE_FILE_PATH="${OUT_DIR}${OUT_FL}.x.c"
    if [ -f "$C_SOURCE_FILE_PATH" ]; then
        rm $C_SOURCE_FILE_PATH &> /dev/null
        return $?
    fi
    return 1
}

function create_compose_file () {
    echo "$COMPOSE_SHEBANG
    " > "$OUTPUT_FILE_PATH"
    return $?
}

function merge_compose_file_paths_into_single_shell_script () {
    if [ ! -f "$OUTPUT_FILE_PATH" ]; then
        create_compose_file
        if [ $? -ne 0 ]; then
            echo "[ ERROR ]: Could not create compose shell script ($OUTPUT_FILE_PATH)."
            return 1
        fi
    fi
    local ERRORS=0
    for fl_path in ${COMPOSE_FILES[@]}; do
        merge_files "$OUTPUT_FILE_PATH" "$fl_path"
        if [ $? -ne 0 ]; then
            local ERRORS=$((ERRORS + 1))
            echo "[ NOK ]: Could not compose shell script ($fl_path)."
            continue
        fi
        echo "[ OK ]: Composed shell script ($fl_path)."
    done
    if [ $ERRORS -ne 0 ]; then
        echo "[ WARNING ]: Composed ($OUTPUT_FILE_PATH) with ($ERRORS) errors."
    fi
    echo "[ DONE ]: Shell script composition complete!"
    return $ERRORS
}

function extract_compose_file_paths_from_compose_directory_set () {
    for dir_path in ${COMPOSE_DIRECTORIES[@]}; do
        if [ ! -d "$dir_path" ]; then
            echo "[ WARNING ]: Invalid path ($dir_path), directory not found."
            continue
        fi
        COMPOSE_FILES=( ${COMPOSE_FILES[@]} "`find $dir_path -type -f | grep '.sh$'`" )
    done
    echo ${COMPOSE_FILES[@]}
    return $?
}

# ACTIONS

function action_compile () {
    FORMATTED_ARGUMENTS=( `format_shell_to_c_arguments` )
    if [[ "$VERBOSE_FLAG" == 'on' ]]; then
        shc ${FORMATTED_ARGUMENTS[@]}
    else
        shc ${FORMATTED_ARGUMENTS[@]} &> /dev/null
    fi
    if [[ "$KEEP_C_SOURCE_CODE_FLAG" == 'off' ]]; then
        remove_c_source_file
    else
        OUT_DIR="`dirname $OUTPUT_FILE_PATH`/"
        if [[ "$OUT_DIR" == './/' ]]; then
            OUT_DIR=''
        fi
        OUT_FL=`basename $TARGET_FILE_PATH`
        C_SOURCE_FILE_PATH="${OUT_DIR}${OUT_FL}.x.c"
        if [ ! -f "$C_SOURCE_FILE_PATH" ]; then
            echo "[ NOK ]: Something went wrong, no C source file created."
            return 1
        fi
        if [ ! -z $C_SOURCE_FILE_PATH ]; then
            CFL_SHORT=`shorten_file_path "$C_SOURCE_FILE_PATH"`
        else
            CFL_SHORT=""
        fi
        echo "[ OK ]: Created C source code file ($CFL_SHORT)"
    fi
    if [ ! -f "$OUTPUT_FILE_PATH" ]; then
        echo "[ NOK ]: Something went wrong, no binary file created."
        return 2
    fi
    if [ ! -z $OUTPUT_FILE_PATH ]; then
        BFL_SHORT=`shorten_file_path "$OUTPUT_FILE_PATH"`
    else
        BFL_SHORT=""
    fi
    echo "[ OK ]: Created binary file ($BFL_SHORT)."
    echo "[ DONE ]: Shell script compilation complete!"
    return 0
}

function action_compose () {
    extract_compose_file_paths_from_compose_directory_set &> /dev/null
    merge_compose_file_paths_into_single_shell_script
    return $?
}

# INIT

function init_game_changer () {
    display_banner; echo
    if [ ! -z $OUTPUT_FILE_PATH ]; then
        OFL_SHORT=`shorten_file_path "$OUTPUT_FILE_PATH"`
    else
        OFL_SHORT=""
    fi
    case "$COMPOSE_FLAG" in
        'on'|'On'|'ON')
            echo "[ $SCRIPT_NAME ]: Composing shell scripts to ($OFL_SHORT)"
            action_compose
            ;;
        'off'|'Off'|'OFF')
            if [ ! -z $TARGET_FILE_PATH ]; then
                TFL_SHORT=`shorten_file_path "$TARGET_FILE_PATH"`
            else
                TFL_SHORT=""
            fi
            echo "[ $SCRIPT_NAME ]: Compile ($TFL_SHORT) to ($OFL_SHORT)"
            action_compile
            ;;
    esac
    return $?
}

# DISPLAY

function display_banner () {
    display_header
    if [ ! -z $TARGET_FILE_PATH ]; then
        TFL_SHORT=`shorten_file_path "$TARGET_FILE_PATH"`
    else
        TFL_SHORT=""
    fi
    if [ ! -z $OUTPUT_FILE_PATH ]; then
        OFL_SHORT=`shorten_file_path "$OUTPUT_FILE_PATH"`
    else
        OFL_SHORT=""
    fi
    if [ ${#COMPOSE_FILES[@]} -ne 0 ]; then
        CFLS=${COMPOSE_FILES[@]}
        CFLS_SHORT="${CFLS:0:10}..."
    else
        CFLS_SHORT=
    fi
    if [ ${#COMPOSE_DIRECTORIES[@]} -ne 0 ]; then
        CDIRS=${COMPOSE_DIRECTORIES[@]}
        CDIRS_SHORT="${CDIRS:0:10}..."
    else
        CDIRS_SHORT=
    fi
    echo "
    [ VERSION             ]: $VERSION_NO $VERSION
    [ EXPIRATION DATE     ]: $EXPIRATION_DATE
    [ EXPIRATION MESSAGE  ]: `echo ${EXPIRATION_MSG:0:10}... | sed 's/^$//g'`
    [ TARGET FILE         ]: $TFL_SHORT
    [ COMPOSE FILES       ]: $CFLS_SHORT
    [ COMPOSE DIRECTORIES ]: $CDIRS_SHORT
    [ OUTPUT FILE         ]: $OFL_SHORT
    [ VERBOSE             ]: $VERBOSE_FLAG
    [ COMPOSE             ]: $COMPOSE_FLAG
    [ SETUID              ]: $SETUID_FLAG
    [ DEBUG EXEC          ]: $DEBUG_EXEC_CALLS_FLAG
    [ RELAX SECURITY      ]: $RELAX_SECURITY_FLAG
    [ UNTRACEABLE         ]: $UNTRACEABLE_BINARY_FLAG
    [ HARDENED            ]: $HARDENED_BINARY_FLAG
    [ BUSYBOX             ]: $COMPILE_FOR_BUSYBOX_FLAG
    " | column
    return $?
}

function display_usage () {
    display_header
    FLNAME=`basename $0`
    cat <<EOF
    [ USAGE ]: ./${FLNAME} (-<command>|--<long-command>)=<value>

    -h | --help                 Display this message.
    -e | --expiration-date      End of life date for compiled binary (DD/MM/YYYY format).
    -m | --expired-message      Message to display to user if compiled binary is expired.
    -t | --target-file          Path to shell script to compile.
    -d | --compose-directory    Path of directory containing shell scripts to compose with
                                (supports multi-call).
    -f | --compose-file         Path of shell script to compose with (supports multi-call).
    -o | --output-file          Path of the new shell script created by the Compose engine,
                                (running mode Compose) or of the compiled binary file
                                (running mode Compile).
    -v | --verbose              Display more verbose output upon compilation.
    -s | --setuid               Turn on SETUID for root callable compiled binaries.
    -D | --debug-exec           Debug exec calls.
    -r | --relax-security       Make a redistributable binary which executes on different
                                systems running the same operating system.
    -u | --untraceable          Block binary tracing using strace, ptrace. truss, etc.
    -H | --hardened             (BourneShell) Protects against dumping, code injection,
                                cat /proc/pid/cmdline, ptrace, etc.
    -b | --busybox              Compile for busybox.
    -K | --keep-source-code     Keep the C source code file used to generate binary.

    [ EXAMPLE ]: ./${FLNAME}

    (--help                     |-h)
- OR -
    (--expiration-date          |-e)=01/01/2021
    (--expired-message          |-m)='Your license expired on 01/01/2021.'
    (--target-file              |-t)=/path/to/file.sh
    (--compose-out-file         |-c)=/path/to/file.sh
    (--compose-directory        |-d)=/path/to/directory1
    (--compose-directory        |-d)=/path/to/directory2
    (--compose-file             |-f)=/path/to/file1.sh
    (--compose-file             |-f)=/path/to/file2.sh
    (--output-file              |-o)=/path/to/file
    (--verbose                  |-v)
    (--setuid                   |-s)
    (--debug-exec               |-D)
    (--relax-security           |-r)
    (--untraceable              |-u)
    (--hardened                 |-H)
    (--busybox                  |-b)
    (--keep-source-code)        |-K)

EOF
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           *     Game Changer    *           *            *
    _______________________________________________________v.${VERSION_NO}${VERSION}________
               Excellent Regards, the Alveare Solutions #!/Society -x
    "
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
        -e=*|--expiration-date=*)
            EXPIRATION_DATE="${opt#*=}"
            echo "[ SETUP ]: Compiled binary expiration date ($EXPIRATION_DATE)."
            ;;
        -m=*|--expired-message=*)
            EXPIRATION_MSG="${opt#*=}"
            echo "[ SETUP ]: Compiled binary expiration message (${EXPIRATION_MSG:0:10}...)."
            ;;
        -t=*|--target-file=*)
            TARGET_FILE_PATH="${opt#*=}"
            echo "[ SETUP ]: Path to shell script to compile ($TARGET_FILE_PATH)."
            ;;
        -d=*|--compose-directory=*)
            COMPOSE_FLAG='on'
            CMP_DIR_PATH="${opt#*=}"
            COMPOSE_DIRECTORIES=( ${COMPOSE_DIRECTORIES[@]} "$CMP_DIR_PATH" )
            echo "[ SETUP ]: Input compose directory path ($CMP_DIR_PATH)."
            ;;
        -f=*|--compose-file=*)
            COMPOSE_FLAG='on'
            CMP_FILE_PATH="${opt#*=}"
            COMPOSE_FILES=( ${COMPOSE_FILES[@]} "$CMP_FILE_PATH" )
            echo "[ SETUP ]: Input compose file path ($CMP_FILE_PATH)."
            ;;
        -o=*|--output-file=*)
            OUTPUT_FILE_PATH="${opt#*=}"
            echo "[ SETUP ]: Output file ($OUTPUT_FILE_PATH)."
            ;;
        -v|--verbose)
            VERBOSE_FLAG='on'
            echo "[ SETUP ]: Verbose output ($VERBOSE_FLAG)."
            ;;
        -s|--setuid)
            SETUID_FLAG='on'
            echo "[ SETUP ]: Unix access right SETUID ($SETUID_FLAG)."
            ;;
        -D|--debug-exec)
            DEBUG_EXEC_CALLS_FLAG='on'
            echo "[ SETUP ]: Debug EXEC calls ($DEBUG_EXEC_CALLS_FLAG)."
            ;;
        -r|--relax-security)
            RELAX_SECURITY_FLAG='on'
            echo "[ SETUP ]: Relax security ($RELAX_SECURITY_FLAG)."
            ;;
        -u|--untraceable)
            UNTRACEABLE_BINARY_FLAG='on'
            echo "[ SETUP ]: Compile untraceable binary ($UNTRACEABLE_BINARY_FLAG)."
            ;;
        -H|--hardened)
            HARDENED_BINARY_FLAG='on'
            echo "[ SETUP ]: Compile hardened binary ($HARDENED_BINARY_FLAG)."
            ;;
        -b|--busybox)
            COMPILE_FOR_BUSYBOX_FLAG='on'
            echo "[ SETUP ]: Compile for Busybox ($COMPILE_FOR_BUSYBOX_FLAG)."
            ;;
        -K|--keep-source-code)
            KEEP_C_SOURCE_CODE_FLAG='on'
            echo "[ SETUP ]: Keep C source code ($KEEP_C_SOURCE_CODE_FLAG)."
            ;;
    esac
done
clear

init_game_changer
exit $?
