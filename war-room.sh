#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# WAR ROOM - (Docker Container Management)

declare -A DOCKER
declare -A CONTAINER
declare -A SYSTEM_COMMANDS

# HOT PARAMETERS

DOCKER=(
['image']='debian'
['image-tag']='oldstable'
['file']='data/Dockerfile'
['maintainer']='Alveare Solutions #!/Society -x'
['label']='com.alvearesolutions.pack="War Room"'
['volume']='/tmp/war_room'
['shell']='["/bin/bash", "-c"]'
['user']='Ghost'
['stopsig']='SIGTERM'
['health-interval']=15
['health-timeout']=60
['health-retries']=5
['health-script']=
['workdir']="/home/${DOCKER['user']}"
)
CONTAINER_INDEX='data/war-machines.index'
KIT_INSTALLER='setup.sh'
SILENT='off'                            # (on | off)
CONTAINER_COUNT=5
ACTION=                                 # (create-machines | install-kit | teardown-machines | reset-machine)
CONTAINER_ID=
GAME_KIT=

# COLD PARAMETERS

SCRIPT_NAME='War Room'
VERSION='HazardousENV'
VERSION_NO='1.1'
BASE_DOCKER_IMAGE_ID=
SURFACE_DOCKER_IMAGE_ID=
CONTAINER=(
['gamekit-dir']='/root'
['scripts-dir']='/usr/local/bin'
['health-script']='health-check.sh'
)
CONTAINER_PACKAGES=(
'apt-utils'
'wget'
'curl'
'git'
'git-core'
'tar'
'net-tools'
'ifupdown'
'ssh'
'netcat'
'telnet'
'busybox'
'elinks'
'tmux'
'vim'
'net-tools'
'bash'
'sed'
'gawk'
'ed'
'netcat'
'tree'
'htop'
'file'
'bc'
'python'
'python3'
'cron'
'sudo'
)
DEPENDENCIES=(
'docker'
'docker.io'
'sed'
'gawk'
'tar'
)

# FETCHERS

function fetch_indexed_container_ids () {
    local CIDS=( `echo "${SYSTEM_COMMANDS['fetch-indexed-cids']}" | bash` )
    if [ ${#CIDS[@]} -eq 0 ]; then
        return 1
    fi
    echo ${CIDS[@]}
    return $?
}

function fetch_all_container_ids () {
    local CONTAINER_IDS=`${SYSTEM_COMMANDS['fetch-cids']}`
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "${CONTAINER_IDS[@]}"
    return 0
}

# CHECKERS

function check_container_indexed () {
    local CID="$1"
    local LINE_NO=`awk -F, -v cid="$CID" \
        '$1 !~ "#" && $1 !~ "^$" && $2 == cid {print NR; exit 0}' \
        "$CONTAINER_INDEX"`
    if [ $? -ne 0 ] || [ -z "$LINE_NO" ]; then
        return 1
    fi
    return 0
}

# FORMATTERS

function format_container_index_record () {
    local MACHINE_ID="$1"
    local MACHINE_LABEL=`${SYSTEM_COMMANDS['docker-containers']} | \
        grep "$MACHINE_ID" | awk '{print $NF}'`
    echo "${MACHINE_LABEL},${MACHINE_ID},vacant,${SURFACE_DOCKER_IMAGE_ID},${BASE_DOCKER_IMAGE_ID},${GAME_KIT}"
    return $?
}

function format_surface_docker_file_content () {
    cat <<EOF
FROM $BASE_DOCKER_IMAGE_ID
RUN echo "[ OK ]: Docker surface image created! Built on top of: ($BASE_DOCKER_IMAGE_ID)"
EOF
    return $?
}

function format_container_index_content () {
    local MACHINE_IDS=( $@ )
    for mid in ${MACHINE_IDS[@]}; do
        local RECORD=`format_container_index_record "$mid"`
        echo "$RECORD" >> ${CONTAINER_INDEX}
    done
    return $?
}

function format_docker_file_content_game_kit () {
    cat<<EOF
ADD "$GAME_KIT" "${CONTAINER['gamekit-dir']}/${GAME_KIT}"
RUN "${SYSTEM_COMMANDS['unpack-tarball']} ${CONTAINER['gamekit-dir']}/${GAME_KIT}"
RUN "${CONTAINER['gamekit-dir']}/\`echo ${GAME_KIT} | cut -d'.' -f 1\`/${KIT_INSTALLER}"
EOF
    return $?
}

function format_docker_file_content_healthcheck () {
    cat<<EOF
ADD "${DOCKER['health-script']}" "${CONTAINER['scripts-dir']}/${CONTAINER['health-script']}"
HEALTHCHECK --interval=$DOCKER['health-interval']} \
            --timeout=${DOCKER['health-timeout']} \
            --retries=${DOCKER['health-retries']} \
            CMD [ "${CONTAINER['scripts-dir']}/${CONTAINER['health-script']}" ]
EOF
    return $?
}

function format_docker_file_content () {
    cat<<EOF
FROM ${DOCKER['image']}:${DOCKER['image-tag']}
MAINTAINER ${DOCKER['maintainer']}
LABEL ${DOCKER['label']}
SHELL ${DOCKER['shell']}
VOLUME ${DOCKER['volume']}
ENV WR_STATE_DIR ${DOCKER['volume']}
WORKDIR ${DOCKER['workdir']}
STOPSIGNAL ${DOCKER['stopsig']}
RUN ${SYSTEM_COMMANDS['apt-update']}
RUN ${SYSTEM_COMMANDS['apt-install']} ${CONTAINER_PACKAGES[@]}
RUN ${SYSTEM_COMMANDS['add-user']} --password ${DOCKER['user']} ${DOCKER['user']}
RUN chown ${DOCKER['user']} ${DOCKER['workdir']} && chmod 755 -R ${DOCKER['workdir']}
USER ${DOCKER['user']}
EOF
    if [ ! -z "${DOCKER['health-script']}" ]; then
        format_docker_file_content_health_check
    fi
    if [ ! -z "$GAME_KIT" ]; then
        format_docker_file_content_game_kit
    fi
    return $?
}

# VALIDATORS

# [ TODO ]: Improve validation procedures in next major version. Check for data
#           type and missing files or directories.

function validate_action_machine_shell_data_set () {
    case "" in
        $CONTAINER_INDEX)
            echo "[ NOK ]: Invalid container index! ($CONTAINER_INDEX)"
            return 1
            ;;
        $CONTAINER_ID)
            echo "[ NOK ]: Invalid container ID! ($CONTAINER_ID)"
            return 1
            ;;
    esac
    echo "[ OK ]: Validated data set for action (machine-shell)."
    return 0
}

function validate_action_reset_machine_data_set () {
    case "" in
        $CONTAINER_INDEX)
            echo "[ NOK ]: Invalid container index! ($CONTAINER_INDEX)"
            return 1
            ;;
        $CONTAINER_ID)
            echo "[ NOK ]: Invalid container ID! ($CONTAINER_ID)"
            return 1
            ;;
    esac
    echo "[ OK ]: Validated data set for action (reset-machine)."
    return 0
}

function validate_action_teardown_machines_data_set () {
    case "" in
        $CONTAINER_INDEX)
            echo "[ NOK ]: Invalid container index! ($CONTAINER_INDEX)"
            return 1
            ;;
    esac
    echo "[ OK ]: Validated data set for action (teardown-machines)."
    return 0
}

function validate_action_install_kit_data_set () {
    case "" in
        $CONTAINER_INDEX)
            echo "[ NOK ]: Invalid container index! ($CONTAINER_INDEX)"
            return 1
            ;;
        $CONTAINER_ID)
            echo "[ NOK ]: Invalid container ID! ($CONTAINER_ID)"
            return 2
            ;;
        $GAME_KIT)
            echo "[ NOK ]: Invalid game kit! ($GAME_KIT)"
            return 3
            ;;
        $KIT_INSTALLER)
            echo "[ NOK ]: Invalid game kit installer! ($KIT_INSTALLER)"
            return 4
            ;;
        ${CONTAINER['gamekit-dir']})
            echo "[ NOK ]: Invalid container game kit directory!"\
                "(${CONTAINER['gamekit-dir']})"
            return 5
            ;;
    esac
    echo "[ OK ]: Validated data set for action (install-kit)."
    return 0
}

function validate_action_create_machines_data_set () {
    case "" in
        $CONTAINER_INDEX)
            echo "[ NOK ]: Invalid container index! ($CONTAINER_INDEX)"
            return 1
            ;;
        $CONTAINER_COUNT)
            echo "[ NOK ]: Invalid number of containers! ($CONTAINER_COUNT)"
            return 2
            ;;
        ${DOCKER['image']})
            echo "[ NOK ]: Invalid Docker image! (${DOCKER['image']})"
            return 3
            ;;
        ${DOCKER['file']})
            echo "[ NOK ]: Invalid Dockerfile! (${DOCKER['file']})"
            return 4
            ;;
        ${DOCKER['user']})
            echo "[ NOK ]: Invalid container user! ($DOCKER['user']))"
            return 5
            ;;
    esac
    echo "[ OK ]: Validated data set for action (create-machines)."
    return 0
}

# ENSURANCE

function ensure_docker_container_running () {
    ${SYSTEM_COMMANDS['docker-exec']} "${CONTAINER_ID}" 'ls' &> /dev/null
    if [ $? -eq 0 ]; then
        return 0
    fi
    ${SYSTEM_COMMANDS['docker-start']} "${CONTAINER_ID}" &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not ensure Docker container is running!"\
            "(${CONTAINER_ID})"
    else
        echo "[ OK ]: Docker container surely running! (${CONTAINER_ID})"
    fi
    return $EXIT_CODE
}

function ensure_docker_daemon () {
    ${SYSTEM_COMMANDS['docker-status']} &> /dev/null
    if [ $? -eq 0 ]; then
        echo "[ OK ]: Docker daemon is already running! Skipping setup..."
        return 0
    fi
    ${SYSTEM_COMMANDS['docker-start-service']} &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not start Docker daemon!"\
            "(${SYSTEM_COMMANDS['docker-start-service']}) ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully started Docker daemon!"
    fi
    return $EXIT_CODE
}

function ensure_surface_docker_file () {
    create_surface_docker_file
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] || [ ! -f ${DOCKER['file']} ]; then
        echo "[ NOK ]: Could not create surface image Dockerfile!"\
            "(${DOCKER['file']}) ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully created Surface Dockerfile!"
    fi
    return $EXIT_CODE
}

function ensure_docker_file () {
    if [ -f "${DOCKER['file']}" ] && [ -r "${DOCKER['file']}" ]; then
        echo "[ OK ]: Using existent Dockerfile! (${DOCKER['file']})"
        return 0
    fi
    echo "[ INFO ]: No Dockerfile found! Building... (${DOCKER['file']})"
    create_docker_file
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ] || [ ! -f ${DOCKER['file']} ]; then
        echo "[ NOK ]: Could not create base image Dockerfile!"\
            "(${DOCKER['file']}) ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully created Base Dockerfile!"
    fi
    return $EXIT_CODE
}

function ensure_container_index () {
    if [ -f "$CONTAINER_INDEX" ] && [ -r "$CONTAINER_INDEX" ]; then
        return 0
    elif [ ! -f $CONTAINER_INDEX ]; then
        echo "[ INFO ]: Container index file not found! Building..."\
            "($CONTAINER_INDEX)"
        touch $CONTAINER_INDEX &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not create container index!"
            return 1
        fi
        echo "[ OK ]: Successfully created container index!"
    else
        echo "[ INFO ]: No read permissions on container index! Granting..."\
            "($CONTAINER_INDEX)"
        chmod +r $CONTAINER_INDEX &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[ NOK ]: Could not grant read permissions to container index!"
            return 2
        fi
        echo "[ OK ]: Successfully granted read permissions to container index!"
    fi
    return 0
}

# BUILDERS

function build_docker_image_base () {
    local DOCKERFILE_DIR=`dirname ${DOCKER['file']}`
    ${SYSTEM_COMMANDS['docker-build']} ${DOCKER['file']} -t base \
        ${DOCKERFILE_DIR} &> /dev/null
    local IMAGE_ID=`${SYSTEM_COMMANDS['docker-imgs']} | \
        grep 'base' | awk '{print $3}'`
    local EXIT_CODE=$?
    echo "$IMAGE_ID"
    return $EXIT_CODE
}

function build_docker_image_surface () {
    local DOCKERFILE_DIR=`dirname ${DOCKER['file']}`
    ${SYSTEM_COMMANDS['docker-build']} ${DOCKER['file']} \
        -t surface ${DOCKERFILE_DIR} &> /dev/null
    local IMAGE_ID=`${SYSTEM_COMMANDS['docker-imgs']} | \
        grep 'surface' | awk '{print $3}'`
    local EXIT_CODE=$?
    echo "$IMAGE_ID"
    return $EXIT_CODE
}

# CREATORS

function create_surface_docker_file () {
    format_surface_docker_file_content > "${DOCKER['file']}"
    return $?
}

function create_docker_file () {
    format_docker_file_content > "${DOCKER['file']}"
    return $?
}

# FILTERS

function filter_container_status () {
    local INDEX_RECORD="$1"
    local CSTS=`echo "$INDEX_RECORD" | awk -F, '{print $3}'`
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "$CSTS"
    return $?
}

function filter_container_id () {
    local INDEX_RECORD="$1"
    local CID=`echo "$INDEX_RECORD" | awk -F, '{print $2}'`
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "$CID"
    return $?
}

# UPDATERS

function update_container_status () {
    local MACHINE_ID="$1"
    local MACHINE_STATUS="$2"
    local LINE_NO=`awk -F, -v cid="$MACHINE_ID" \
        '$1 !~ "#" && $1 !~ "^#" && $2 ~ cid {print NR; exit 0}' \
        "$CONTAINER_INDEX"`
    local MODDED_LINE=`awk -F, -v line_no=$LINE_NO \
        -v mstatus="$MACHINE_STATUS"\
        'BEGIN { OFS="," } \
        NR == line_no {print $1, $2, mstatus, $4, $5, $6; exit 0}' \
        "$CONTAINER_INDEX"`
    sed -i "${LINE_NO}s/.*/$MODDED_LINE/" "$CONTAINER_INDEX" &> /dev/null
    return $?
}

function update_container_game_kit () {
    local MACHINE_ID="$1"
    local GAME_KIT="$2"
    local LINE_NO=`awk -F, -v cid="$MACHINE_ID" \
        '$1 !~ "#" && $1 !~ "^#" && $2 ~ cid {print NR; exit 0}' \
        "$CONTAINER_INDEX"`
    local MODDED_LINE=`awk -F, -v line_no=$LINE_NO \
        -v game_kit="$GAME_KIT"\
        'BEGIN { OFS="," } \
        NR == line_no {print $1, $2, $3, $4, $5, game_kit; exit 0}' \
        "$CONTAINER_INDEX"`
    sed -i "${LINE_NO}s/.*/$MODDED_LINE/" "$CONTAINER_INDEX" &> /dev/null
    return $?
}

function update_container_index () {
    local INDEX_RECORD="$1"
    local CONTAINER_ID=`filter_container_id "$INDEX_RECORD"`
    local LINE_NO=`awk -F, -v cid="$CONTAINER_ID" \
        '$2 ~ cid {print NR; exit 0}' "$CONTAINER_INDEX"`
    if [ $? -ne 0 ] || [ -z "$LINE_NO" ]; then
        echo "$INDEX_RECORD" >> ${CONTAINER_INDEX}
    else
        local CONTAINER_STATUS=`filter_container_status "$INDEX_RECORD"`
        local MODDED_LINE=`awk -F, -v cid="$CONTAINER_ID" \
            -v csts="$CONTAINER_STATUS" 'BEGIN { OFS="," } \
            $2 ~ cid {print $1, $2, csts, $4, $5, $6; exit 0}' $CONTAINER_INDEX`
        sed -i "${LINE_NO}s/.*/${MODDED_LINE}/" $CONTAINER_INDEX &> /dev/null
    fi
    return $?
}

# CLEANERS

function cleanup_docker_file () {
    rm -f ${DOCKER['file']} &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not cleanup Dockerfile! (${DOCKER['file']})"
    else
        echo "[ OK ]: Successfully cleaned up Dockerfile!"
    fi
    return $EXIT_CODE
}

function clean_container_index () {
    echo -n > $CONTAINER_INDEX
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not clear container index! ($CONTAINER_INDEX)"
    else
        echo "[ OK ]: Successfully cleared container index!"
    fi
    return $EXIT_CODE
}

function cleanup_container_index () {
    rm -f $CONTAINER_INDEX &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not cleanup container index! ($CONTAINER_INDEX)"
    else
        echo "[ OK ]: Successfully cleaned up container index!"
    fi
    return $EXIT_CODE
}

# GENERAL

function start_docker_surface_container () {
    local SURFACE_IMG_ID="$1"
    local CID=`${SYSTEM_COMMANDS['docker-run-detached']} ${SURFACE_IMG_ID} \
        tail -f \/dev\/null; cat /proc/1/cpuset | tr '/' ' ' | awk '{print $NF}'`
    local SHORT_CID="${CID:0:12}"
    echo "$SHORT_CID"
    return $?
}

function refresh_container_index () {
    local FAILURES=0
    local CONTAINER_IDS=( `fetch_all_container_ids` )
    local CONTAINER_INDEX_CONTENT="`format_container_index_content ${CONTAINER_IDS[@]}`"
    echo "$CONTAINER_INDEX_CONTENT" > "$CONTAINER_INDEX"
    local UPDT_EXIT_CODE=$?
    local FAILURES=$((FAILURES + $UPDT_EXIT_CODE))
    if [ $UPDT_EXIT_CODE -ne 0 ]; then
        echo "[ WARNING ]: Could not update container index! ($CONTAINER_INDEX)"
    fi
    return $FAILURES
}

# ACTIONS

function action_install_kit () {
    local KIT_FILE=`basename ${GAME_KIT}`
    echo "[ INFO ]: Provisioning container..."\
        "(${CONTAINER_ID}:${CONTAINER['gamekit-dir']}/${KIT_FILE})"
    ensure_docker_container_running
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Not sure target Docker container is running!"
    fi
    ${SYSTEM_COMMANDS['docker-provision']} "$GAME_KIT" \
        "${CONTAINER_ID}:${CONTAINER['gamekit-dir']}" &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not provision container with game kit!"
        return 1
    else
        echo "[ OK ]: Successfully provisioned container with game kit!"
    fi
    local KIT_DIR=`echo "$KIT_FILE" | cut -d'.' -f1`
    local CDIR="${CONTAINER['gamekit-dir']}/${KIT_DIR}"
    local CPATH="${CDIR}/${KIT_INSTALLER}"
    local CMD="tar -xf ${CONTAINER['gamekit-dir']}/${KIT_FILE} --directory ${CONTAINER['gamekit-dir']}"
    echo "[ INFO ]: Unpacking game kit... (${CMD})"
    ensure_docker_container_running
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Not sure target Docker container is running!"
    fi
    ${SYSTEM_COMMANDS['docker-exec']} "$CONTAINER_ID" $CMD &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not unpack game kit!"
    else
        echo "[ OK ]: Game kit unpacked!"
    fi
    echo "[ INFO ]: Setting installer execution rights..."
    ensure_docker_container_running
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Not sure target Docker container is running!"
    fi
    ${SYSTEM_COMMANDS['docker-exec']} $CONTAINER_ID chown root $CDIR &> /dev/null
    ${SYSTEM_COMMANDS['docker-exec']} $CONTAINER_ID chmod +x -R $CDIR &> /dev/null
    ${SYSTEM_COMMANDS['docker-exec']} $CONTAINER_ID chmod +s -R $CDIR &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not set execution rights!"
    else
        echo "[ OK ]: Install is executable!"
    fi
    echo "[ INFO ]: Executing game kit installer... (${CPATH})"
    ensure_docker_container_running
    ${SYSTEM_COMMANDS['docker-exec']} $CONTAINER_ID $CPATH
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not execute game kit installer!"
    else
        echo "[ OK ]: Successfully installed game kit! ($CPATH)"
        update_container_game_kit "$CONTAINER_ID" "$GAME_KIT"
    fi
    return $EXIT_CODE
}

function action_reset_machine () {
    echo "[ INFO ]: Storing container surface image..."
    SURFACE_DOCKER_IMAGE_ID=`awk -F, -v cid="$CONTAINER_ID" \
        '$1 !~ "#" && $1 !~ "^#" && $2 == cid {print $4}' \
        "$CONTAINER_INDEX"`
    BASE_DOCKER_IMAGE_ID=`awk -F, -v cid="$CONTAINER_ID" \
        '$1 !~ "#" && $1 !~ "^#" && $2 == cid {print $5}' \
        "$CONTAINER_INDEX"`
    if [ $? -ne 0 ] || [ -z "$SURFACE_DOCKER_IMAGE_ID" ]; then
        echo "[ NOK ]: Could not identify container surface image to reset!"\
            "($CONTAINER_ID)"
        return 1
    fi
    echo "[ OK ]: Successfully identifierd container surface image!"\
        "($SURFACE_DOCKER_IMAGE_ID)"
    echo "[ INFO ]: Stopping Docker container... (${CONTAINER_ID})"
    ${SYSTEM_COMMANDS['docker-stop']} "${CONTAINER_ID}" &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not stop Docker containers! ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully stop Docker containers!"
    fi
    echo "[ INFO ]: Removing container... ($CONTAINER_ID)"
    ${SYSTEM_COMMANDS['docker-rmc']} "$CONTAINER_ID" &> /dev/null
    local LINE_NO=`awk -F, -v cid="$CONTAINER_ID" \
        '$1 !~ "#" && $1 !~ "^$" && $2 == cid {print NR; exit 0}' \
        "$CONTAINER_INDEX"`
    sed -i "${LINE_NO}d" "$CONTAINER_INDEX" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: Could not remove container index record!"\
            "(${CONTAINER_ID})"
    fi
    echo "[ INFO ]: Spawning container from surface image..."\
        "($SURFACE_DOCKER_IMAGE_ID)"
    local MACHINE_ID=`start_docker_surface_container "$SURFACE_DOCKER_IMAGE_ID"`
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not start Docker surface container! ($EXIT_CODE)"
        return 2
    fi
    echo "[ OK ]: Container spawned! ($MACHINE_ID)"
    local INDEX_RECORD=`format_container_index_record "$MACHINE_ID"`
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not format container index record!"\
            "($MACHINE_ID) ($EXIT_CODE)"
    fi
    update_container_index "$INDEX_RECORD"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not update container index!"\
            "($CONTAINER_INDEX) ($EXIT_CODE)"
    fi
    return 0
}

function action_set_docker_setuid_bit () {
    local DOCKER_PATH=`which docker`
    echo "[ INFO ]: Adding SETUID bit on executable! ($DOCKER_PATH)"
    echo "${SYSTEM_COMMANDS['docker-setuid']}" | bash &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[ NOK ]: Could not set SETUID bit on executable! ($DOCKER_PATH)"
        return 1
    fi
    echo "[ OK ]: Successfully added SETUID bit!"
    return 0
}

function action_install_dependencies () {
    if [ ${#DEPENDENCIES[@]} -eq 0 ]; then
        echo "[ WARNING ]: No dependencies found!"
        return 1
    fi
    local FAILURES=0
    echo "[ INFO ]: Updating APT package manager..."
    ${SYSTEM_COMMANDS['apt-update']} &> /dev/null
    if [ $? -ne 0 ]; then
        local FAILURES=$((FAILURES + 1))
        echo "[ NOK ]: Update failed! (${FAILURES})"
    else
        echo "[ OK ]: Update complete!"
    fi
    for pkg in ${DEPENDENCIES[@]}; do
        echo "[ INFO ]: Installing package... ($pkg)"
        ${SYSTEM_COMMANDS['apt-install']} "$pkg" &> /dev/null
        if [ $? -ne 0 ]; then
            local FAILURES=$((FAILURES + 1))
            echo "[ NOK ]: Installation failed!"\
                "(${SYSTEM_COMMANDS['apt-install']} $pkg)"
        else
            echo "[ OK ]: Installation complete!"
        fi
    done
    return $FAILURES
}

function action_machine_shell () {
    echo "[ INFO ]: Going down the RABBIT Hole... (${CONTAINER_ID})
    "
    ${SYSTEM_COMMANDS['docker-exec-user']} "${CONTAINER_ID}" "/bin/bash"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: RABBIT Hole failure! Could not access machine shell."
        return 1
    fi
    return $EXIT_CODE
}

function action_teardown_machines () {
    local INDEXED_CONTAINER_IDS=( `fetch_indexed_container_ids` )
    echo "[ INFO ]: Stopping Docker containers... (${#INDEXED_CONTAINER_IDS[@]})"
    ${SYSTEM_COMMANDS['docker-stop']} ${INDEXED_CONTAINER_IDS[@]} &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not stop Docker containers! ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully stop Docker containers!"
    fi
    echo "[ INFO ]: Removing Docker containers... (${#INDEXED_CONTAINER_IDS[@]}) "
    ${SYSTEM_COMMANDS['docker-rmc']} ${INDEXED_CONTAINER_IDS[@]} &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not remove Docker containers! ($EXIT_CODE)"
    else
        echo "[ OK ]: Successfully removed Docker containers!"
    fi
    echo "[ INFO ]: Removing Docker images... (base, surface)"
    ${SYSTEM_COMMANDS['docker-rmi']} "base" "surface" &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ WARNING ]: Could not remove Docker images!"
    else
        echo "[ OK ]: Successfully removed Docker images!"
    fi
    return $EXIT_CODE
}

function action_create_machines () {
    local FAILURES=0
    echo "[ INFO ]: Building base Docker image - this might take a while..."
    BASE_DOCKER_IMAGE_ID=`build_docker_image_base`
    local EXIT_CODE=$?
    if [ -z "$BASE_DOCKER_IMAGE_ID" ] || [ $EXIT_CODE -ne 0 ]; then
        local FAILURES=$((FAILURES + 1))
        echo "[ NOK ]: Could not build Docker base image! ($EXIT_CODE)"
        return $FAILURES
    fi
    ensure_surface_docker_file
    local FAILURES=$((FAILURES + $EXIT_CODE))
    echo "[ INFO ]: Building surface Docker image - this won't take as long..."
    SURFACE_DOCKER_IMAGE_ID=`build_docker_image_surface`
    local EXIT_CODE=$?
    if [ -z "$SURFACE_DOCKER_IMAGE_ID" ] || [ $EXIT_CODE -ne 0 ]; then
        local FAILURES=$((FAILURES + 1))
        echo "[ NOK ]: Could not build Docker surface image! ($EXIT_CODE)"
        return $FAILURES
    fi
    for machine_no in `seq $CONTAINER_COUNT`; do
        echo "[ INFO ]; Spawning container no.($machine_no)..."
        local MACHINE_ID=`start_docker_surface_container "$SURFACE_DOCKER_IMAGE_ID"`
        local EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            local FAILURES=$((FAILURES + 1))
            echo "[ NOK ]: Could not start Docker surface container! ($EXIT_CODE)"
            continue
        fi
        echo "[ OK ]: Container spawned! ($MACHINE_ID)"
        local INDEX_RECORD=`format_container_index_record "$MACHINE_ID"`
        local EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            local FAILURES=$((FAILURES + 1))
            echo "[ NOK ]: Could not format container index record!"\
                "($MACHINE_ID) ($EXIT_CODE)"
        fi
        update_container_index "$INDEX_RECORD"
        local EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            local FAILURES=$((FAILURES + 1))
            echo "[ NOK ]: Could not update container index!"\
                "($CONTAINER_INDEX) ($EXIT_CODE)"
        fi
    done
    if [ $FAILURES -eq 0 ]; then
        echo "[ OK ]: Construction complete!"\
            "($CONTAINER_COUNT) Game Machines online!"
    fi
    return $FAILURES
}

# HANDLERS

function handle_action_install_kit () {
    local FAILURES=0
    validate_action_install_kit_data_set
    local FAILURES=$((FAILURES + $?))
    action_install_kit
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
                "($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

function handle_action_setup () {
    local FAILURES=0
    action_install_dependencies
    local FAILURES=$((FAILURES + $?))
    action_set_docker_setuid_bit
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
            "($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

function handle_action_machine_shell () {
    local FAILURES=0
    validate_action_machine_shell_data_set
    local FAILURES=$((FAILURES + $?))
    action_machine_shell
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
                "($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

function handle_action_reset_machine () {
    local FAILURES=0
    validate_action_reset_machine_data_set
    local FAILURES=$((FAILURES + $?))
    check_container_indexed "$CONTAINER_ID"
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
                "($FAILURES) failures! ($ACTION)"
        return $FAILURES
    fi
    action_reset_machine
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
                "($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

function handle_action_teardown_machines () {
    local FAILURES=0
    validate_action_teardown_machines_data_set
    local FAILURES=$((FAILURES + $?))
    action_teardown_machines
    local EXIT_CODE=$?
    local FAILURES=$((FAILURES + $?))
    if [ $EXIT_CODE -eq 0 ]; then
        cleanup_container_index
        local FAILURES=$((FAILURES + $?))
        cleanup_docker_file
        local FAILURES=$((FAILURES + $?))
    fi
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected"\
            "($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

function handle_action_create_machines () {
    local FAILURES=0
    validate_action_create_machines_data_set
    local FAILURES=$((FAILURES + $?))
    ensure_container_index
    local FAILURES=$((FAILURES + $?))
    ensure_docker_file
    local FAILURES=$((FAILURES + $?))
    ensure_docker_daemon
    local FAILURES=$((FAILURES + $?))
    action_create_machines
    local FAILURES=$((FAILURES + $?))
    if [ $FAILURES -ne 0 ]; then
        echo "[ WARNING ]: Action handler detected ($FAILURES) failures! ($ACTION)"
    fi
    return $FAILURES
}

# DISPLAY

function display_header () {
    echo "
    ___________________________________________________________________________

     *                         *      ${SCRIPT_NAME}      *                        *
    _____________________________________________________v${VERSION_NO}${VERSION}______
               Excellent Regards, the Alveare Solutions #!/Society -x
    "
}

function display_usage () {
    display_header
    cat <<EOF
    -h   | --help                Display this message.

    -s   | --setup               Install project dependencies.

    -c=  | --container-id=       Docker container ID to use for action.

    -i=  | --kit-installer=      Script found inside the Game Kit directory.

    -s   | --silent              Suppress output.

    -m=  | --machine-index=      Path to Docker container index file.

    -C=  | --create-machines=    Sets action to (create-machines). Receives the
         |                       number of Docker containers to spawn.

    -R=  | --reset-machine=      Sets action to (reset-machine). Delete and
         |                       recreate surface Docker container specified by
         |                       container ID.

    -T   | --teardown-machines   Sets action to (teardown-machines). Destroys
         |                       all Docker containers and images. Removes
         |                       container index file.

    -I=  | --install-kit=        Sets action to (install-kit). Receives path to
         |                       Game Kit tarball.

    -S=  | --machine-shell=      Gives the user an interactive shell to the
         |                       specified Docker container. Receives container ID.

    --docker-image=              Image for Docker to build the base image on.

    --docker-image-tag=          Tag to use for specified Docker image.

    --docker-file=               Path to Dockerfile to use while building the
                                 base image.

    --docker-maintainer=         Maintainer - Docker image metadata.

    --docker-label=              Label - Docker image metadata.

    --docker-volume=             Volume - Path to mount point holding externally
                                 mounted volumes from native host or other
                                 containers.

    --docker-shell=              Default shell for game machines.

    --docker-user=               Default non-root user for game machines.

    --docker-stop-sig=           Sets the system call signal that will be sent
                                 to the container to exit. This signal can be a
                                 valid unsigned number that matches a position
                                 in the kernel’s syscall table, for instance 9,
                                 or a signal name in the format SIGNAME, for
                                 instance SIGKILL.

    --docker-health-script=      Path to script to use as Docker container
                                 health check.

    --docker-health-interval=    The health check will first run interval seconds
                                 after the container is started, and then again
                                 interval seconds after each previous check
                                 completes.

    --docker-health-timeout=     If a single run of the check takes longer than
                                 timeout seconds then the check is considered to
                                 have failed.

    --docker-health-retries=     It takes retries consecutive failures of the
                                 health check for the container to be considered
                                 unhealthy.

    --docker-workdir=            Sets the working directory for any Docker RUN,
                                 CMD, ENTRYPOINT, COPY and ADD instructions that
                                 follow it in the Dockerfile.

    [ EXAMPLE ]: Install project dependencies -

        ~$ sudo ./war_room.sh --setup

    [ EXAMPLE ]: Install wargame kit on virtual war room -

        ~$ ./war-room.sh \
                --container-id=container-id
                --install-kit=/path/to/game/kit.tar
                --kit-installer=setup.sh
                --machine-index=/path/to/index/file

    [ EXAMPLE ]: Reset machine - will destroy the virtual war room and create a
                 blank one in it's place -

        ~$ ./war-room.sh \
                --reset-machine=container-id
                --machine-index=/path/to/index/file

    [ EXAMPLE ]: Login to virtual war room shell -

        ~$ ./war-room.sh \
                --machine-shell=container-id
                --machine-index=/path/to/index/file

EOF
    return $?
}

# INIT

function init_war_room () {
    display_header
    case "$ACTION" in
        'create-machines')
            handle_action_create_machines
            ;;
        'reset-machine')
            handle_action_reset_machine
            ;;
        'teardown-machines')
            handle_action_teardown_machines
            ;;
        'install-kit')
            handle_action_install_kit
            ;;
        'machine-shell')
            handle_action_machine_shell
            ;;
        'setup')
            handle_action_setup
            ;;
        *)
            echo "[ ERROR ]: Invalid action detected! ($ACTION)"
            return 1
            ;;
    esac
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not handle action! ($ACTION)"
    else
        echo "[ OK ]: Successfully handled action! ($ACTION)"
    fi
    return $EXIT_CODE
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
        --setup)
            if [ $EUID -ne 0 ]; then
                display_usage
                echo "[ WARNING ]: --setup requires priviledged access rigts! Are you root?"
                exit 2
            fi
            ACTION='setup'
            ;;
        -c=*|--container-id=*)
            CONTAINER_ID="${opt#*=}"
            ;;
        -i=*|--kit-installer=*)
            KIT_INSTALLER="${opt#*=}"
            ;;
        -s|--silent)
            if [ -z "$SILENT" ] || [[ "$SILENT" == "on" ]]; then
                SILENT="off"
            else
                SILENT="on"
            fi
            ;;
        -m=*|--machine-index=*)
            CONTAINER_INDEX="${opt#*=}"
            ;;
        -C=*|--create-machines=*)
            ACTION='create-machines'
            CONTAINER_COUNT=${opt#*=}
            ;;
        -R=*|--reset-machine=*)
            ACTION='reset-machine'
            CONTAINER_ID="${opt#*=}"
            ;;
        -T|--teardown-machines)
            ACTION='teardown-machines'
            ;;
        -I=*|--install-kit=*)
            ACTION='install-kit'
            GAME_KIT="${opt#*=}"
            ;;
        -S=*|--machine-shell=*)
            ACTION='machine-shell'
            CONTAINER_ID="${opt#*=}"
            ;;
        --docker-image=*)
            DOCKER['image']="${opt#*=}"
            ;;
        --docker-image-tag=*)
            DOCKER['image-tag']="${opt#*=}"
            ;;
        --docker-file=*)
            DOCKER['file']="${opt#*=}"
            ;;
        --docker-maintainer=*)
            DOCKER['maintainer']="${opt#*=}"
            ;;
        --docker-label=*)
            DOCKER['label']="${opt#*=}"
            ;;
        --docker-volume=*)
            DOCKER['volume']="${opt#*=}"
            ;;
        --docker-shell=*)
            DOCKER['shell']="${opt#*=}"
            ;;
        --docker-user=*)
            DOCKER['user']="${opt#*=}"
            ;;
        --docker-stop-sig=*)
            DOCKER['stopsig']="${opt#*=}"
            ;;
        --docker-health-interval=*)
            DOCKER['health-interval']="${opt#*=}"
            ;;
        --docker-health-timeout=*)
            DOCKER['health-timeout']="${opt#*=}"
            ;;
        --docker-health-retries=*)
            DOCKER['health-retries']="${opt#*=}"
            ;;
        --docker-health-script=*)
            DOCKER['health-script']="${opt#*=}"
            ;;
        --docker-workdir=*)
            DOCKER['workdir']="${opt#*=}"
            ;;
    esac
done

SYSTEM_COMMANDS=(
['docker-images']='docker images'
['docker-containers']='docker ps -a'
['docker-start-service']='service docker start'
['docker-run']='docker run -it '                         # + <image-id> <command>
['docker-run-detached']='docker run -d '                 # + <image-id> <command>
['docker-build']='docker build -f '                      # + <dockerfile-path> <directory>
['docker-start']='docker start '                         # + <container-id>
['docker-stop']='docker stop '                           # + <container-id>
['docker-status']='service docker status'
['docker-imgs']='docker images'
['docker-rmc']='docker rm '                              # + <container-id>
['docker-rmi']='docker rmi '                             # + <image-id>
['docker-provision']='docker cp '                        # + <src-path> <container-id>:<dst-path>
['docker-exec']='docker exec -u0 -it '                   # + <container-id> <command>
['docker-exec-user']='docker exec -it '                  # + <container-id> <command>
['apt-update']='apt-get update'
['apt-install']='apt-get install -y '                    # + <packages>
['apt-uninstall']='apt-get remove -y '                   # + <packages>
['add-user']="useradd --create-home --shell /bin/bash "  # + --password <password> <username>
['interface-up']="ifup "                                 # + <interface>
['interface-down']="ifdown "                             # + <interface>
['unpack-tarball']="tar -xf "                            # + <archive>
['fetch-interface']="ifconfig | grep 'UP' | grep 'BROADCAST' | awk -F: '{print \$1}'"
['fetch-cids']="docker ps -a | awk '{print \$1}' | grep -v CONTAINER"
['fetch-indexed-cids']="awk -F, '\$1 !~ \"#\" && \$1 !~ \"^$\" {print \$2}' $CONTAINER_INDEX"
['ssh-start']="service ssh start"
['docker-setuid']="chown root \`which docker\` && chmod +s \`which docker\` || exit 1"
)

case "$SILENT" in
    'on')
        init_war_room &> /dev/null
        ;;
    *)
        init_war_room
        ;;
esac

EXIT_CODE=$?
echo; exit $EXIT_CODE

# CODE DUMP

