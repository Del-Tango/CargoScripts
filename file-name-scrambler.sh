#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# FILE NAME SCRAMBLER

declare -A FILE_PATHS
declare -A SCRAMBLED_PATHS

TARGET_DIRECTORY=
TARGET_FILE=
FILE_PATHS=
SCRAMBLED_PATHS=

# FETCHERS

function fetch_directory_content () {
    local DIR_PATH="$1"
    find "$DIR_PATH" -type f
    return $?
}

function fetch_file_name_from_path () {
    local FILE_PATH="$1"
    local FILE_NAME=`basename "$FILE_PATH"`
    echo "$FILE_NAME"
    return $?
}

function fetch_file_paths () {
    for item in ${!FILE_PATHS[@]}; do
        if [ -z "${FILE_PATHS[$item]}" ]; then
            continue
        fi
        echo "$item:${FILE_PATHS[$item]}"
    done
    return 0
}

function fetch_scrambled_paths () {
    for item in ${!SCRAMBLED_PATHS[@]}; do
        if [ -z "${SCRAMBLED_PATHS[$item]}" ]; then
            continue
        fi
        echo "$item:${SCRAMBLED_PATHS[$item]}"
    done
    return 0
}

function fetch_directory_name_from_path () {
    local FILE_PATH="$1"
    dirname $FILE_PATH
    return $?
}

# SETTERS

function set_file_paths () {
    local DIR_PATH="$1"
    for path in `fetch_directory_content "$DIR_PATH"`; do
        FILE_NAME=`fetch_file_name_from_path "$path"`
        FILE_PATHS["$FILE_NAME"]="$path"
    done
    return 0
}

function set_file_path () {
    local FILE_PATH="$1"
    FILE_NAME=`fetch_file_name_from_path "$FILE_PATH"`
    FILE_PATHS[$FILE_NAME]="$FILE_PATH"
    return 0
}

# SCRAMBLERS

function scramble_file_name () {
    RANDSEQ=`generate_random_sequence`
    PATH_PREFIX=`fetch_directory_name_from_path "$TARGET_FILE"`
    local RE_NAME="${PATH_PREFIX}/${RANDSEQ}"
    rename_file "$TARGET_FILE" "$RE_NAME"
    SCRAMBLED_PATHS[$RANDSEQ]="$RE_NAME"
    return 0
}

function scramble_directory_content () {
    for item in ${!FILE_PATHS[@]}; do
        if [ -z "${FILE_PATHS[$item]}" ]; then
            continue
        fi
        RANDSEQ=`generate_random_sequence`
        if [ ! -z "${SCRAMBLED_PATHS[$RANDSEQ]}" ]; then
            while :
            do
                RANDSEQ=`generate_random_sequence`
                if [ ! -z "${SCRAMBLED_PATHS[$RANDSEQ]}" ]; then
                    continue
                fi
                break
            done
        fi
        PATH_PREFIX=`fetch_directory_name_from_path "${FILE_PATHS[$item]}"`
        local RE_NAME="${PATH_PREFIX}/${RANDSEQ}"
        rename_file "${FILE_PATHS[$item]}" "$RE_NAME"
        SCRAMBLED_PATHS[$RANDSEQ]="$RE_NAME"
    done
    return 0
}

# GENERAL

function generate_random_sequence () {
    echo $RANDOM
    return $?
}

function rename_file () {
    local ORIGINAL_NAME="$1"
    local RE_NAME="$2"
    mv "$ORIGINAL_NAME" "$RE_NAME"
    return $?
}

function list_content () {
    if [ -z "$TARGET_FILE" ] && [ -z "$TARGET_DIRECTORY" ]; then
        return 2
    fi
    if [ ! -z "$TARGET_FILE" ]; then
        fetch_file_paths
    elif [ ! -z "$TARGET_DIRECTORY" ]; then
        fetch_file_paths
    fi
    return $?
}

# INIT

function init_file_name_scramble () {
    scramble_file_name
    echo "===[ FILES ]==="
    fetch_file_paths
    echo "===[ SCRAMBLED ]==="
    fetch_scrambled_paths
    return $?
}

function init_directory_content_scramble () {
    scramble_directory_content
    echo "===[ FILES ]==="
    fetch_file_paths
    echo "===[ SCRAMBLED ]==="
    fetch_scrambled_paths
    return $?
}

# DISPLAYS

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           * File Name Scrambler *           *            *
    ___________________________________________________________________________
                       Regards, the Alveare Solutions society.
    "
}

function display_usage () {
    display_header
    cat <<EOF
    [ DESCRIPTION ]: Payload.

    [ USAGE ]: $0 -f=<file-path> -d=<directory-path> -l

    -h  | --help              Display this message.
    -l  | --list              Lists out the file paths without scrambling.
    -f= | --file=             If used with -l lists full file path. Else,
                              scrambles file name.
    -d= | --directory=        If used with -l lists all file paths in directory,
                              Else, scrambles all file names.

    [ EXAMPLE ]: $0

    (--file      | -f)=/path/to/file1
    (--file      | -f)=/path/to/file2
    (--directory | -d)=/path/to/directory1
    (--directory | -d)=/path/to/directory2
    (--list      | -l)

EOF
}

# MISCELLANEOUS

if [ $# -eq 0 ] || [ $# -gt 3 ]; then
    echo "[ ERROR ]: Invalid number of arguments."
    display_usage
    exit 1
fi

for opt in "$@"
do
    case "$opt" in
        -f=*|--file=*)
            TARGET_FILE="${opt#*=}"
            set_file_path "$TARGET_FILE"
            ;;
        -d=*|--directory=*)
            TARGET_DIRECTORY="${opt#*=}"
            set_file_paths "$TARGET_DIRECTORY"
            ;;
    esac
done

for opt in "$@"
do
    case "$opt" in
        -h|--help)
            display_usage
            exit 0
            ;;
        -l|--list)
            echo "===[ FILES ]==="
            list_content
            exit 0
            ;;
    esac
done

for opt in "$@"
do
    case "$opt" in
        -f=*|--file=*)
            init_file_name_scramble
            ;;
        -d=*|--directory=*)
            init_directory_content_scramble
            ;;
    esac
done

exit $?
