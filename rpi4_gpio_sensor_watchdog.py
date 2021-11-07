#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# PortALL - Low Level Sensor Watchdog

import RPi.GPIO as GPIO
import datetime
import time
import logging
import optparse
import os
#import pysnooper

from subprocess import run

SCRIPT_NAME = '(PA)Watchdog'
VERSION = 'GTC'
VERSION_NO = '1.0'

WD_DEFAULT = {
    'project-dir': '/home/pi/PortALL',
    'log-dir': None,
    'log-file': 'log/portall.log',
    'temperature-file': '/sys/class/thermal/thermal_zone0/temp',
    'log-record-format': '[ %(asctime)s ] %(name)s [ %(levelname)s ] - %(filename)s - %(lineno)d: %(funcName)s - %(message)s',
    'log-date-format': '%d-%m-%Y %H:%M:%S',
    'gpio-action': False,
    'pin-state': True,
    'pin-number': None,
    'pin-mode': 'out',      # (in|out)
    'gpio-mode': GPIO.BCM,
    'pi-warnings': False,
    'scan-interval': 0.5,   # Seconds
    'light-timer': 5,       # Minutes
    'light-timestamp': None,
    'day-light': False,
    'error-flag': False,
    'debug-flag': False,
}

WD_TEMPERATURE = {
    'max-threshold': 65,    # Celsius
    'min-threshold': 55,    # Celsius
}

WD_SENSOR_SCAN = {
    'cooling-fan': None,
    'temperature': None,
    'timestamp': None,
    'proximity': None,
    'ambiental-light': None,
    'main-light': None,
    'button-lamp': None,
}

WD_PIN_STATES = {
    True: GPIO.HIGH,
    False: GPIO.LOW,
}

# FETCHERS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def fetch_machine_temperature():
    log.debug('')
    with open(WD_DEFAULT['temperature-file']) as f:
        temp_str = f.read()
    try:
        temperature = int(temp_str) / 1000
    except Exception as e:
        log.warning(e)
        temperature = None
    return temperature

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def fetch_error_flag():
    log.debug('')
    return WD_DEFAULT['error-flag']

# SETTERS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def set_main_light_state(state):
    log.debug('')
    global WD_SENSOR_SCAN
    try:
        GPIO.output(WD_PINS['out']['main-light'], WD_PIN_STATES[state])
        WD_SENSOR_SCAN['main-light'] = GPIO.input(WD_PINS['out']['main-light'])
    except Exception as e:
        log.error(e)
        set_error_flag(True)
        return False
    return WD_SENSOR_SCAN['main-light']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def set_cooling_fan_state(state):
    log.debug('')
    global WD_SENSOR_SCAN
    try:
        GPIO.output(WD_PINS['out']['cooling-fan'], WD_PIN_STATES[state])
        WD_SENSOR_SCAN['cooling-fan'] = GPIO.input(WD_PINS['out']['cooling-fan'])
    except Exception as e:
        log.error(e)
        set_error_flag(True)
    return WD_SENSOR_SCAN['cooling-fan']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def set_button_lamp_state(state):
    log.debug('')
    global WD_SENSOR_SCAN
    try:
        GPIO.output(WD_PINS['out']['button-lamp'], WD_PIN_STATES[state])
        WD_SENSOR_SCAN['button-lamp'] = GPIO.input(WD_PINS['out']['button-lamp'])
    except Exception as e:
        log.error(e)
        set_error_flag(True)
        return False
    return WD_SENSOR_SCAN['button-lamp']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def set_error_flag(flag_value):
    log.debug('')
    global WD_DEFAULT
    if not isinstance(flag_value, bool):
        return False
    WD_DEFAULT['error-flag'] = flag_value
    if WD_DEFAULT['error-flag']:
        log.error('Errors detected! Something went wrong...')
    return WD_DEFAULT['error-flag']

# CHECKERS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def check_minutes_passed(minutes, since):
    log.debug('')
    now = datetime.datetime.now()
    try:
        difference = now - since
    except Exception as e:
        log.error(e)
        return False
    return True if int(difference.total_seconds() / 60) > minutes else False

# HANDLERS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def handle_action():
    global WD_PINS
    log.info('One-off GPIO action exec...')

    if WD_DEFAULT['pin-mode'] == 'out':
        WD_PINS['out']['action'] = WD_DEFAULT['pin-number']
        GPIO.setup(WD_DEFAULT['pin-number'], GPIO.OUT)
        GPIO.output(WD_PINS['out']['action'], WD_PIN_STATES[WD_DEFAULT['pin-state']])
        print('GPIO pin', WD_DEFAULT['pin-number'], 'state:', GPIO.input(WD_PINS['out']['action']))

    elif WD_DEFAULT['pin-mode'] == 'in':
        WD_PINS['in']['action'] = WD_DEFAULT['pin-number']
        GPIO.setup(WD_DEFAULT['pin-number'], GPIO.IN)
        print('GPIO pin', WD_DEFAULT['pin-number'], 'state:', GPIO.input(WD_PINS['in']['action']))

    else:
        log.warning(
            'Invalid GPIO action pin mode! ({})'.format(WD_DEFAULT['pin-mode'])
        )
        return False
    return True

def handle_reset_button_press(pin_number):
    log.debug('Event triggered for pin ({})'.format(pin_number))
    log.info('Reset button press detected! System going down for reboot...')
    if not WD_DEFAULT['debug-flag']:
        reboot = run(['reboot'])
        exit_code = True if reboot.returncode == 0 else False
    else:
        log.warning('DEBUG mode activated. System cowardly refuses to reboot!')
        exit_code = False
    return exit_code

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def handle_main_light_cooldown():
    log.debug('')
    if WD_SENSOR_SCAN['main-light'] == 1:
        main_light_timeout = check_minutes_passed(
            WD_DEFAULT['light-timer'], WD_DEFAULT['light-timestamp']
        )
        if main_light_timeout:
            return False
    return True if WD_SENSOR_SCAN['main-light'] == 1 else False

# GENERAL

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def sensor_state_scan():
    log.debug('')
    global WD_SENSOR_SCAN
    WD_SENSOR_SCAN = {
        'timestamp': datetime.datetime.now(),
        'proximity': GPIO.input(WD_PINS['in']['proximity']),
        'ambiental-light': GPIO.input(WD_PINS['in']['ambiental-light']),
        'main-light': GPIO.input(WD_PINS['out']['main-light']),
        'button-lamp': GPIO.input(WD_PINS['out']['button-lamp']),
        'temperature': fetch_machine_temperature(),
        'cooling-fan': GPIO.input(WD_PINS['out']['cooling-fan']),
    }
    log.debug('WD_SENSOR_SCAN: {}'.format(WD_SENSOR_SCAN))
    return WD_SENSOR_SCAN

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def take_action(action_response):
    log.debug('')
    handlers = {
        'main-light': set_main_light_state,
        'button-lamp': set_button_lamp_state,
        'cooling-fan': set_cooling_fan_state,
    }
    for action in action_response:
        if action not in handlers.keys():
            continue
        handlers[action](action_response[action])
    return WD_SENSOR_SCAN

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def start_watchdog():
    log.debug('')
    while True:
        try:
            sensor_data = sensor_state_scan()
            action_response = process_sensor_data_for_action(sensor_data)
            take_action(action_response)
        except Exception as e:
            set_error_flag(True)
            log.error(e)
        finally:
            time.sleep(WD_DEFAULT['scan-interval'])

# PROCESSORS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_pin_state_argument(parser, options):
    global WD_DEFAULT
    pin_state = options.pin_state.lower()
    if not pin_state:
        return False
    WD_DEFAULT['pin-state'] = True if pin_state == 'high' else False
    return WD_DEFAULT['pin-state']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_sensor_data_for_action(sensor_data):
    log.debug('')
    return {
        'main-light': process_main_light_sensor_data(sensor_data),
        'button-lamp': process_button_lamp_sensor_data(sensor_data),
        'cooling-fan': process_cooling_fan_sensor_data(sensor_data),
    }

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_cooling_fan_sensor_data(sensor_data):
    log.debug('')
    if sensor_data['temperature'] > WD_TEMPERATURE['max-threshold']:
        log.debug('Turning on cooling fan!')
        set_cooling_fan_state(True)
    elif sensor_data['temperature'] < WD_TEMPERATURE['min-threshold'] \
            and sensor_data['cooling-fan'] is 1:
        log.debug('Turning off cooling fan!')
        set_cooling_fan_state(False)
    return False if WD_SENSOR_SCAN['cooling-fan'] == 0 else True

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_main_light_sensor_data(sensor_data):
    global WD_DEFAULT
    log.debug('')
    if sensor_data['proximity'] == 1 and sensor_data['ambiental-light'] != 0:
        WD_DEFAULT['light-timestamp'] = sensor_data['timestamp']
        return True
    elif sensor_data['ambiental-light'] == 0:
        return False
    return handle_main_light_cooldown()

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_button_lamp_sensor_data(sensor_data):
    log.debug('')
    if not fetch_error_flag():
        return False
    return False if sensor_data['button-lamp'] == 1 else True

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_action_argument(parser, options):
    global WD_DEFAULT
    gpio_action = options.gpio_action.lower()
    if not gpio_action or gpio_action not in ('on', 'off'):
        return False
    WD_DEFAULT['gpio-action'] = True if gpio_action == 'on' else False
    return WD_DEFAULT['gpio-action']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_pin_number_argument(parser, options):
    global WD_DEFAULT
    pin_number = options.gpio_pin
    if not pin_number:
        return False
    WD_DEFAULT['pin-number'] = pin_number
    return WD_DEFAULT['pin-number']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_pin_mode_argument(parser, options):
    global WD_DEFAULT
    pin_mode = options.pin_mode.lower()
    if not pin_mode:
        return False
    WD_DEFAULT['pin-mode'] = pin_mode
    return WD_DEFAULT['pin-mode']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_gpio_mode_argument(parser, options):
    global WD_DEFAULT
    gpio_mode = options.gpio_mode.lower()
    if not gpio_mode:
        return False
    if gpio_mode == 'board':
        default_mode = GPIO.BOARD
    else:
        default_mode = GPIO.BCM
    WD_DEFAULT['gpio-mode'] = default_mode
    return WD_DEFAULT['gpio-mode']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_log_file_argument(parser, options):
    global WD_DEFAULT
    log_file = options.log_file
    if not log_file or not os.path.exists(log_file):
        return False
    WD_DEFAULT['log_file'] = log_file
    return WD_DEFAULT['log_file']

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def process_command_line_options(parser):
    (options, args) = parser.parse_args()
    processed = {
        'log_file': process_log_file_argument(parser, options),
        'action': process_action_argument(parser, options),
        'pin_number': process_pin_number_argument(parser, options),
        'pin_mode': process_pin_mode_argument(parser, options),
        'gpio_mode': process_gpio_mode_argument(parser, options),
        'pin_state': process_pin_state_argument(parser, options),
    }
    return processed

# CREATORS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def create_command_line_parser():
    parser = optparse.OptionParser(
        'Execute one-off action (set single GPIO pin state) -\n\n~$ %prog \ \n'
        '   -a | --action \ \n'
        '   -l | --log-file=/path/to/file \ \n'
        '   -p | --pin-number=5 \ \n'
        '   -m | --pin-mode=OUT \ \n'
        '   -M | --gpio-mode=BCM \ \n'
        '   -s | --pin-state=HIGH \n\n'
        'Start sensor watchdog daemon -\n\n~$ %prog \ \n'
        '   -l | --log-file=/path/to/file '
    )
    return parser

# PARSERS

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def add_command_line_parser_options(parser):
    parser.add_option(
        '-l', '--log-file', dest='log_file', type='string',
        help='File path to log messages to',
    )
    parser.add_option(
        '-a', '--action', dest='gpio_action', type='string',
        help='GPIO action mode',
    )
    parser.add_option(
        '-p', '--pin-number', dest='gpio_pin', type='int',
        help='Pin number to user for action. Implies (-a | --action)'
    )
    parser.add_option(
        '-m', '--pin-mode', dest='pin_mode', type='string',
        help='GPIO pin mode - IN/OUT. Implies (-p | --pin-number)'
    )
    parser.add_option(
        '-M', '--gpio-mode', dest='gpio_mode', type='string',
        help='GPIO numbering mode - BCM/Board. Implies (-p | --pin-number)'
    )
    parser.add_option(
        '-s', '--pin-state', dest='pin_state', type='string',
        help='GPIO pin state to set - HIGH/LOW. Implies (-p | --pin-number)'
    )
    return parser

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def parse_command_line_arguments():
    parser = create_command_line_parser()
    add_command_line_parser_options(parser)
    return process_command_line_options(parser)

# SETUP

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def setup_gpio():
    log.info('Setting GPIO warnings to ({})'.format(WD_DEFAULT['pi-warnings']))
    GPIO.setwarnings(WD_DEFAULT['pi-warnings'])

    log.info('Setting GPIO mode to ({})'.format(WD_DEFAULT['gpio-mode']))
    GPIO.setmode(WD_DEFAULT['gpio-mode'])

    if isinstance(WD_DEFAULT['pin-number'], int):
        pin_mode = GPIO.IN if WD_DEFAULT['pin-mode'] == 'in' else GPIO.OUT
        log.info('Setting up GPIO action pin ({})'.format(WD_DEFAULT['pin-number']))
        GPIO.setup(WD_DEFAULT['pin-number'], pin_mode)

        return True

    log.info('Setting up GPIO IN pins ({})'.format(list(WD_PINS['in'].values())))
    GPIO.setup(list(WD_PINS['in'].values()), GPIO.IN)

    log.info('Setting up GPIO OUT pins ({})'.format(list(WD_PINS['out'].values())))
    GPIO.setup(list(WD_PINS['out'].values()), GPIO.OUT)

    log.info('Setting up GPIO IN&OUT pins ({})'.format(
        list(WD_PINS['both'][data_set_key]['pin'] for data_set_key in WD_PINS['both']))
    )
    for data_set_key in WD_PINS['both']:
        data_set = WD_PINS['both'][data_set_key]
        pull_resistor = GPIO.PUD_UP if data_set['pull'] == 'up' else GPIO.PUD_DOWN
        GPIO.setup(data_set['pin'], GPIO.IN, pull_up_down=pull_resistor)
        GPIO.add_event_detect(
            data_set['pin'], GPIO.BOTH, callback=data_set['event-callback']
        )

    return True

# INIT

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def init_log():
    if not WD_DEFAULT['log-file'] or not WD_DEFAULT['project-dir']:
        return False
    full_path = '/'.join([WD_DEFAULT['project-dir'], WD_DEFAULT['log-file']])
    log = logging.getLogger(SCRIPT_NAME or __name__)
    log.setLevel(logging.DEBUG)
    file_handler = logging.FileHandler(full_path, 'a')
    formatter = logging.Formatter(
        WD_DEFAULT['log-record-format'],
        WD_DEFAULT['log-date-format'],
    )
    file_handler.setFormatter(formatter)
    log.addHandler(file_handler)
    return log

#@pysnooper.snoop(WD_DEFAULT['log-file'])
def init_watchdog():
    log.info('Initializing {} {}{}'.format(SCRIPT_NAME, VERSION_NO, VERSION))
    setup_gpio()
    if WD_DEFAULT['gpio-action']:
        handle_action()
    else:
        start_watchdog()

# MISCELLANEOUS

WD_PINS = {
    'in': {
        'proximity': 5,
        'ambiental-light': 27,
        'reset-button': 26,
    },
    'out': {
        'main-light': 18,
        'cooling-fan': 22,
        'button-lamp': 12,
    },
    'both': {
        'reset-button': {
            'pin': 26,
            'pull': 'up',
            'event-callback': handle_reset_button_press,
        }
    },
    'action': None,
}

if __name__ == '__main__':
    parse_command_line_arguments()
    log = init_log()
    try:
        init_watchdog()
    finally:
        if WD_DEFAULT['gpio-action']:
            log.warning('One off action complete. Not cleaning up GPIO pins!')
            exit(0)
        GPIO.cleanup()

# CODE DUMP

