#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# Plaza Terminal - Making it easier than ever to Orbit a PlazaHotel room at boot!

# Hot Parameters
PLAZA_ALIAS="`whoami`"
PLAZA_ADDRESS='127.0.0.1'
PLAZA_PORT=8080
PLAZA_FLOOR=0
PLAZA_ROOM=0
PLAZA_KEY=''

# Cold Parameters
TMP_DIR='/tmp'
OPT_DIR='/opt'
PLAZA_DIR="${OPT_DIR}/PlazaHotel-IMServer-Client"
PLAZA_INIT="${PLAZA_DIR}/plaza-init"
PLAZA_CARGO="${PLAZA_DIR}/src/plaza_hotel.py"
LOG_FILE="${PLAZA_HOTEL}/logs/plaza-hotel.log"
RUNNING_MODE='client'
CLIENT_TYPE='guest'
OPERATION='join'
SILENT='off'
STATE_FILE="${TMP_DIR}/phs.tmp"
STATE_FIFO="${TMP_DIR}/phs.fifo"
RESPONSE_FIFO="${TMP_DIR}/phr.fifo"

# FORMATTERS

function format_ph_cargo_arguments() {
	local ARGUMENTS=(
	"--log-file ${LOG_FILE}"
	"--running-mode ${RUNNING_MODE}"
	"--silent-flag ${SILENT}"
	"--port-number ${PLAZA_PORT}"
	"--address ${PLAZA_ADDRESS}"
	"--client-type ${CLIENT_TYPE}"
	"--alias ${PLAZA_ALIAS}"
	"--operation ${OPERATION}"
	"--floor-number ${PLAZA_FLOOR}"
	"--room-number ${PLAZA_ROOM}"
	"--state-file ${STATE_FILE}"
	"--state-fifo ${STATE_FIFO}"
	"--response-fifo ${RESPONSE_FIFO}"
	)
	echo -n "${ARGUMENTS[@]}"
	return $?
}

# ACTIONS

function cargo_action() {
	local ARGUMENTS=( $@ )
	trap 'trap - SIGINT; echo ''[ SIGINT ]: Terminating...''; return 1' SIGINT
	echo; ${PLAZA_CARGO} ${ARGUMENTS[@]} 2> /dev/null; trap - SIGINT
	return $?
}

# INIT

function plaza_terminal() {
	cargo_action `format_ph_cargo_arguments`
	return $?
}

# MISCELLANEOUS

plaza_terminal
exit $?


