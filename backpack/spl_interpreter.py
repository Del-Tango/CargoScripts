#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Serial Power Link Interpreter

import os
import datetime
import pysnooper
import serial
import logging
import RPi.GPIO as GPIO
import time

from .bp_ensurance import *
from .bp_checkers import *
from .bp_log import *
from .bp_generators import generate_msg_id

log = logging.getLogger('')


class SPLInterpreter(object):
    '''
    [ NOTE ]: SPL message interpreter.
    [ EX   ]: SPL message format -
              SPLT:<gate-id>,<machine-id>,<machine-ipv4>,<message-id>,<message>;
    '''

    message_types = ['ID', 'ACK', 'INT']
    gpio_state = {
        True: GPIO.HIGH,
        False: GPIO.LOW,
    }

    def __init__(self, *args, **kwargs):
        self.last_csv = kwargs.get('last_csv', str())
        self.timestamp = datetime.datetime.now()
        self.spl_index = kwargs.get('spl_index', '.fg_head.spl.index')
        self.machine_id = kwargs.get('machine_id', 'FG.HEAD.01')
        self.machine_ipv4 = kwargs.get('machine_ipv4', '192.168.100.1')
        self.spl_reader = kwargs.get('spl_reader', serial.Serial(
            kwargs.get('serial_port', '/dev/serial0'),
            baudrate=kwargs.get('baudrate', 115200),
            bytesize=kwargs.get('bytesize', 8),
            parity=kwargs.get('parity', 'N'),
            stopbits=kwargs.get('stopbits',1),
            timeout=kwargs.get('timeout', 3.0),
        ))
        self.spl_writer = kwargs.get('spl_writer', serial.Serial(
            kwargs.get('serial_port', '/dev/serial0'),
            baudrate=kwargs.get('baudrate', 115200),
            bytesize=kwargs.get('bytesize', 8),
            parity=kwargs.get('parity', 'N'),
            stopbits=kwargs.get('stopbits',1),
            timeout=kwargs.get('timeout', 3.0),
        ))
        self.spl_actions = kwargs.get(
            'spl_actions', {
                'IN': {}, 'OUT': {}, 'AIR': {}, '1': {}, '2': {}, '3': {}, '4': {}
            }
        )
        self.spl_report_pipe = kwargs.get(
            'report_pipe', ensure_fifo_exists('/tmp/.fg-spl-report.fifo')
        )
        self.spl_gate_pins = kwargs.get('spl_gate_pins', {
            'IN': 19, 'OUT': 16, 'AIR': 26, '1': 19, '2': 16, '3': 26, '4': 20,
        })
        log.debug('SPL Interpreter object initialized!')

    # SETTERS

    def set_gate_pin_lock_state(self, gate_id, state):
        log.debug('')
        if GPIO.input(self.spl_gate_pins[gate_id]) is self.gpio_state[state]:
            log.debug('Gate lock pi state already set! ({} - {})'.format(
                gate_id, state
            ))
            return True
        try:
            GPIO.output(self.spl_gate_pins[gate_id], self.gpio_state[state])
        except Exception as e:
            log.error(e)
            return False
        return True

    # CHECKERS

    def check_msg_ack_reply_expected(self, message):
        log.debug('')
        if not self.spl_actions.get(message['local-gate-id']) \
                or not self.spl_actions[message['local-gate-id']].get(message['msg-id']):
            return False
        return self.spl_actions[message['local-gate-id']][message['msg-id']]['reply']

    def check_spl_bus_busy(self):
        log.debug('')
        for gate_id in self.spl_gate_pins:
            if GPIO.input(self.spl_gate_pins[gate_id]) is self.gpio_state[True]:
                return True
        return False

    def check_spl_gate_busy(self, gate_id):
        log.debug('')
        return True if GPIO.input(self.spl_gate_pins[gate_id]) \
            is self.gpio_state[True] else False

    def check_msg_ack_expected(self, msg_dict):
        log.debug('')
        try:
            check = self.spl_actions[str(msg_dict['local-gate-id'])]\
                [str(msg_dict['msg-id'])]['action-expected']
        except Exception as e:
            log.error(e)
            return False
        return False if check != 'ACK' else True

    def check_machine_already_identified(self, msg_dict):
        log.debug('')
        if not os.path.exists(self.spl_index):
            try:
                with open(self.spl_index, 'w') as fl:
                    fl.write(self.format_spl_index_content())
            except Exception as e:
                log.error(e)
                return False
        index_content = []
        with open(self.spl_index, 'r') as index:
            index_content = index.readlines()
            log.debug('SPL index content: \n{}'.format(index_content))
        for index_line in index_content:
            try:
                registered_machine_id = index_line.split(',')[2]
            except Exception as e:
                continue
            if msg_dict['src-machine-id'] == registered_machine_id:
                return True
        return False

    # VALIDATORS

    def validate_spl_csv(self, spl_csv_msg):
        log.debug('')
        if spl_csv_msg[0:5] not in ['SPLT:', 'SPLI:'] or spl_csv_msg[-1] != ';' \
                or len(spl_csv_msg.split(',')) > 7:
            return False
        return True

    # CONVERTERS

    def spl_msg_str_2_list(self, spl_csv_msg):
        log.debug('')
        return [
            item.rstrip(';') for item in
            spl_csv_msg.lstrip('SPLT:').rstrip(';').split(',')
        ]

    def spl_msg_list_2_dict(self, msg_list):
        log.debug('')
        message = {
            'src-gate-id': None, 'src-machine-id': None, 'msg-id': None,
            'msg-type': None, 'src-machine-ipv4': None, 'local-gate-id': None,
        }
        try:
            message.update({
                'src-gate-id': msg_list[0],
                'src-machine-id': msg_list[1],
                'src-machine-ipv4': msg_list[2],
                'msg-id': msg_list[3],
                'msg-type': msg_list[4],
            })
        except IndexError as e:
            log.error(e)
        if len(msg_list) > 5:
            message.update({'local-gate-id': msg_list[5]})
        log.debug('SPL message dict: ({})'.format(message))
        return message

    # FORMATTERS

    def format_spl_interogation_request_msg(self, **kwargs):
        log.debug('')
        return "REPORT:{},{};".format(
            kwargs.get('machine_id', self.machine_id),
            kwargs.get('machine_ip', self.machine_ipv4)
        )

    def format_spl_csv_msg(self, action, **kwargs):
        log.debug('')
        return "SPLT:{},{},{},{},{};".format(
            kwargs.get('gate_id', '-'),
            kwargs.get('machine_id', self.machine_id),
            kwargs.get('machine_ip', self.machine_ipv4),
            kwargs.get('msg_id', generate_msg_id(5)),
            action,
        )

    def format_spl_msg_action_record(self, message, **kwargs):
        log.debug('')
        return {
            'machine-id': message.get('src-machine-id'),
            'machine-ip': message.get('src-machine-ipv4'),
            'gate-id': message.get('src-gate-id'),
            'action-expected': kwargs.get('action_expected'),
            'reply': kwargs.get('reply', False),
            'timeout': kwargs.get('timeout', 100),
            'timestamp': kwargs.get('timestamp', datetime.datetime.now()),
            'msg_log': kwargs.get('msg_log', [message])
        }

    def format_ack_response(self, msg_dict):
        log.debug('')
        return ','.join([
            "SPLT:" + msg_dict['local-gate-id'], self.machine_id,
            self.machine_ipv4, msg_dict['msg-id'], 'ACK;'
        ])

    def format_spl_index_content(self):
        '''
        [ NOTE ]: SPL Index file format -

            # HEAD Unit

            IN,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>
            OUT,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>

            # NODE Unit

            1,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>
            2,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>
            3,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>
            4,<remote-gate-id>,<remote-machine-id>,<remote-machine-ipv>
        '''
        log.debug('')
        content = [str(item) + ',' for item in self.spl_gate_pins.keys()]
        return '\n'.join(content)

    # GENERAL

    def wait_for_spl_bus(self, timeout=100):
        log.debug('')
        start = datetime.datetime.now()
        while True:
            check = self.check_spl_bus_busy()
            if not check:
                log.info('SPL bus clear!')
                return True
            now = datetime.datetime.now()
            time_passed = now - start
            if time_passed.seconds > timeout:
                log.warning(
                    'System timed out waiting for SPL bus to clear! ({}sec)'\
                    .format(timeout)
                )
                break
            time.sleep(1)
        return False

    def flood_gate_spl_lock(self, gate_id, state):
        log.debug('')
        for no in range(5):
            set_state = self.set_gate_pin_lock_state(gate_id, state)
            if set_state:
                log.info(
                    'SPL gate lock state set! ({}) ({})'.format(gate_id, state)
                )
                return set_state
            log.warning(
                'SPL gate lock state change attempt ({}) failed! ({}) ({})'\
                .format(no, gate_id, state)
            )
            time.sleep(1)
        return False

    def report_to_head(self):
        '''
        [ NOTE ]: Write to report pipe instruction to notify head that new data
                  is available and that it should interogate this machines at
                  it'searliest convenience
        [ EX   ]: SPLI:interpreter,request-interogation;
        '''
        log.debug('')
        with open(self.spl_report_pipe, 'a') as fifo:
            try:
                fifo.write(self.format_spl_interogation_request_msg())
            except Exception as e:
                log.error(e)
                return False
        return True

    # UPDATERS

    def update_spl_actions_cache(self, gate_id, msg_id, message, **kwargs):
        log.debug('')
        if kwargs.get('action_expected') and kwargs['action_expected'] \
                not in self.message_types:
            log.warning(
                'Invalid SPL action expected parameter! ({}) ({})'\
                .format(kwargs['action-expected'], self.message_types)
            )
            return False
        formatted_meta = self.format_spl_msg_action_record(message, **kwargs)
        if not self.spl_actions.get(gate_id):
            self.spl_actions[gate_id] = {}
        self.spl_actions[gate_id].update({msg_id: formatted_meta})
        log.debug('SPL actions cache: ({})'.format(self.spl_actions))
        return self.spl_actions

    def update_spl_index(self, msg_dict):
        log.debug('')
        old_records, new_records, updated_record = [], [], str()
        with open(self.spl_index, 'r') as fl:
            old_records = fl.readlines()
        for line in old_records:
            if line.split(',')[0] != msg_dict['local-gate-id']:
                new_records.append(line.strip('\n'))
                continue
            updated_record = "{},{},{},{}".format(
                msg_dict['local-gate-id'], msg_dict['src-gate-id'],
                msg_dict['src-machine-id'], msg_dict['src-machine-ipv4']
            )
            log.debug('Updated SPL Index record: ({})'.format(updated_record))
            new_records.append(updated_record)
        log.debug('Writing SPL Index file... ({})'.format(self.spl_index))
        with open(self.spl_index, 'w') as fl:
            fl.write('\n'.join(new_records))
        return True

    # ACTIONS

    def issue_spl_csv_msg(self, gate_id, message, **kwargs):
        log.debug('')
        wait = self.wait_for_spl_bus(timeout=10)
        if not wait:
            log.warning('SPL bus busy!')
            return False
        gate_lock_on = self.flood_gate_spl_lock(gate_id, True)
        if not gate_lock_on:
            log.warning(
                'Could not lock onto gate ({}) SPL transmission pin!'\
                .format(gate_id)
            )
            return False
        serial_write = self.spl_writer.write(message)
        if not serial_write:
            log.error(
                'Could not issue SPL CSV message on gate {}! ({})'.format(
                    gate_id, message
                )
            )
        time.sleep(3)
        gate_lock_off = self.flood_gate_spl_lock(gate_id, False)
        if not gate_lock_off:
            log.warning(
                'Could not unlock gate ({}) SPL transmission pin!'\
                .format(gate_id)
            )
            return False
        return message if serial_write else False

    def issue_spl_id_csv_msg(self, gate_id, **kwargs):
        log.debug('')
        formatted_msg = self.format_spl_csv_msg('ID', gate_id=gate_id, **kwargs)
        return self.issue_spl_csv_msg(gate_id, formatted_msg, **kwargs)

    def issue_spl_int_csv_msg(self, gate_id, **kwargs):
        log.debug('')
        formatted_msg = self.format_spl_csv_msg('INT', gate_id=gate_id, **kwargs)
        return self.issue_spl_csv_msg(gate_id, formatted_msg, **kwargs)

    def issue_spl_ack_csv_msg(self, gate_id, **kwargs):
        log.debug('')
        formatted_msg = self.format_spl_csv_msg('ACK', gate_id=gate_id, **kwargs)
        return self.issue_spl_csv_msg(gate_id, formatted_msg, **kwargs)

    def forward_discovery(self, init_msg_dct, **kwargs):
        log.debug('')
        failures = 0
        log.info('SPL Forward Discovery...')
        for gate_id in self.spl_actions:
            init_discovery = self.issue_spl_id_csv_msg(gate_id, **kwargs)
            issue_interogation_request = self.issue_spl_int_csv_msg(gate_id, **kwargs)
            if not init_discovery or not issue_interogation_request:
                failures += 1
        return False if failures else True

    # HANDLERS

    def handle_int_msg(self, message, **kwargs):
        '''
        [ NOTE ]: Only machines that previously identified themselves are allowed
                  to interogate current unit.
        '''
        log.debug('')
        already_identified = self.check_machine_already_identified(message)
        if not already_identified:
            log.warning(
                'Received interogation request from unknown unit! ({})'\
                .format(message)
            )
            return False
        id_response = self.issue_spl_id_csv_msg(
            message['local-gate-id'], msg_id=message['msg-id'], **kwargs
        )
        if not id_response:
            log.error('Could not issue SPL ID response!')
            return False
        update = self.update_spl_actions_cache(
            message['local-gate-id'], message['msg-id'], message,
            action_expected='ACK', reply=True, timeout=100,
            timestamp=datetime.datetime.now(), msg_log=[
                message, self.spl_msg_list_2_dict(
                    self.spl_msg_str_2_list(id_response)
                )
            ]
        )
        return True

    def handle_id_msg(self, message, **kwargs):
        log.debug('')
        ack_response = self.issue_spl_ack_csv_msg(
            message['local-gate-id'], msg_id=message['msg-id'], **kwargs
        )
        if not ack_response:
            log.error('Could not issue SPL ACK response!')
            return False
        update = self.update_spl_actions_cache(
            message['local-gate-id'], message['msg-id'], message,
            action_expected='ACK', reply=False, timeout=100,
            timestamp=datetime.datetime.now(), msg_log=[
                message, self.spl_msg_list_2_dict(
                    self.spl_msg_str_2_list(ack_response)
                )
            ]
        )
        already_identified = self.check_machine_already_identified(message)
        if not already_identified:
            update_index = self.update_spl_index(message)
        forward_discovery = self.forward_discovery(message)
        report_to_head = self.report_to_head()
        return True

    def handle_ack_msg(self, message, **kwargs):
        '''
        [ NOTE ]: To be used in future version.
        '''
        log.debug('')
        if not self.check_msg_ack_expected(message):
            log.warning('No ACK message expected! Received: ({})'.format(message))
            return False
        if not self.check_msg_ack_reply_expected(message):
            log.info('No ACK reply expected for message: ({})'.format(message))
            return self.cleanup_action_record(message)
        ack_response = self.issue_spl_ack_csv_msg(
            message['local-gate-id'], msg_id=message['msg-id'], **kwargs
        )
        log.debug('ACK response: ({})'.format(ack_response))
        if not ack_response:
            log.warning(
                'Could not issue ACK response to SPL message! ({})'\
                .format(message)
            )
            return False
        return self.cleanup_action_record(message)

    # CLEANUP

    def cleanup_action_record(self, msg_dict):
        log.debug('')
        try:
            log.debug(
                'Cleaning up message record ({}) from cache...'\
                .format(msg_dict.get('msg-id'))
            )
            del self.spl_actions[msg_dict.get('local-gate-id')]\
                [msg_dict.get('msg-id')]
        except Exception as e:
            log.error(e)
            return False
        return True

    def cleanup_action_cache(self):
        timed_out = {}
        for gate_id in self.spl_actions:
            for msg_id in self.spl_actions[gate_id]:
                now = datetime.datetime.now()
                time_passed = now - self.spl_actions[gate_id][msg_id]['timestamp']
                timeout = False if time_passed.seconds \
                    < self.spl_actions[gate_id][msg_id]['timeout'] else True
                if not timeout:
                    continue
                msg_lst = timed_out.get(gate_id,[]) + [msg_id]
                timed_out.update({gate_id: msg_lst})
        for gate_id in timed_out:
            for msg_id in timed_out[gate_id]:
                try:
                    del self.spl_actions[gate_id][msg_id]
                except Exception as e:
                    log.error(e)
        return True

    # INTERPRETERS

    def interpret(self, spl_csv_msg, **kwargs):
        log.debug('')
        if not self.validate_spl_csv(spl_csv_msg):
            return False
        msg_handlers = {
            'ID': self.handle_id_msg,
            'ACK': self.handle_ack_msg,
            'INT': self.handle_int_msg,
        }
        message = self.spl_msg_list_2_dict(self.spl_msg_str_2_list(spl_csv_msg))
        if message['msg-type'] not in msg_handlers.keys():
            log.warning(
                'Invalid message type! Could not interpret: ({})'\
                .format(message)
            )
            return False
        elif not message['local-gate-id']:
            log.warning(
                'Orphan serial message! No SPL gate locked on: ({})'\
                .format(message)
            )
            return False
        try:
            handle = msg_handlers[message['msg-type']](message, **kwargs)
        except Exception as e:
            log.error(e)
            return False
        finally:
            self.cleanup_action_cache()
        return handle


