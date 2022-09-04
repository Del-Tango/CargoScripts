#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Serial Power Link

import serial
import datetime
import os
import queue
import logging

from collections import deque

from .spl_reader import SPLReader
from .spl_writer import SPLWriter
from .spl_interpreter import *

log = logging.getLogger('')


class SPL(object):
    '''
    [ NOTE ]: Serial Power Link interface
    '''
    port_cnx = None
    pin_state = {True: GPIO.HIGH, False: GPIO.LOW}

    def __init__(self, *args, **kwargs):
        self.serial_ports = kwargs.get('serial_ports', args) or ('/dev/serial0')
        for serial_port in args:
            if not serial_port:
                continue
            try:
                self.port_cnx = serial.Serial(
                    serial_port,
                    baudrate=kwargs.get('baudrate', 115200),
                    bytesize=kwargs.get('bytesize', 8),
                    parity=kwargs.get('parity', 'N'),
                    stopbits=kwargs.get('stopbits',1),
                    timeout=kwargs.get('timeout', 3.0),
                )
                break
            except Exception as e:
                log.error(e)
                continue
        self.reader = kwargs.get(
            'reader', SPLReader(*self.serial_ports, port_cnx=self.port_cnx)
        )
        self.writer = kwargs.get(
            'writer', SPLWriter(*self.serial_ports, port_cnx=self.port_cnx)
        )
        self.spl_interpreter = SPLInterpreter(
            spl_reader=self.reader, spl_writer=self.writer, **kwargs
        )
        self.gate_count = kwargs.get('gate_count', 4)
        self.spl_gate_pins = kwargs.get('spl_gate_pins', {
            1: 19, 2: 16, 3: 26, 4: 20,
        })
        self.spl_gates_active = kwargs.get('spl_gates_activedq', list())
        self.message_archive = {
            item: {'message': str(), 'timestamp': None, 'direction': str()}
            for item in self.spl_gate_pins.keys()
        }
        self.pi_warnings = kwargs.get('pi_warnings', False)
        self.gpio_mode = kwargs.get('gpio_mode', GPIO.BCM)
        log.debug('SPL object initialized!')

    # FETCHERS

    def fetch_active_gate_ids(self):
        log.debug('')
        active_gate_locks = [
            gate_id for gate_id in self.spl_gate_pins.keys()
            if GPIO.input(self.spl_gate_pins[gate_id]) == self.pin_state[True]
        ]
        log.debug('Active SPL gate locks: ({})'.format(active_gate_locks))
        return active_gate_locks

    # UPDATERS

    def update_message_archive(self, gate_id, **metadata):
        log.debug('')
        if gate_id not in self.message_archive.keys():
            log.warning('Gate id ({}) not in message archive! ({})'.format(
                gate_id, self.message_archive
            ))
            return False
        self.message_archive[gate_id] = {
            'message': metadata.get('message', ''),
            'timestamp': metadata.get('timestamp'),
            'direction': metadata.get('direction'),
        }
        log.debug('Message archive: ({})'.format(self.message_archive))
        return self.message_archive

    # ACTIONS

    def spl_monitor(self, sys_path, **kwargs):
        '''
        [ NOTE ]: Monitors messages comming through FIFO pipe written by the
                  read2pipe('/path/to/fifo') process, validates and interprets
                  the messages.
        '''
        log.debug('')
        if not check_is_fifo(sys_path) \
                or not check_file_exists(sys_path):
            return False
        with open(sys_path, 'r') as fl:
            while True:
                lines_read = [line.strip('\n') for line in fl.readlines()]
                if not lines_read:
                    time.sleep(0.1)
                    self.spl_interpreter.cleanup_action_cache()
                    continue
                for line in lines_read:
                    log.debug('Interpreting instruction: ({})'.format(line))
                    self.spl_interpreter.interpret(line)

    def interpret(self, spl_csv_msg, **kwargs):
        log.debug('')
        try:
            handle = self.spl_interpreter.interpret(spl_csv_msg, **kwargs)
        except Exception as e:
            log.error(e)
            return False
        return handle

#   @pysnooper.snoop()
    def read2disk(self, sys_path, target='file', **kwargs):
        log.debug('')
        gate_ids = self.fetch_active_gate_ids()
        new_ids = []
        self.cleanup_spl_active_gate_locks_cache()
        for gate_id in gate_ids:
            if gate_id in self.spl_gates_active:
                continue
            new_ids.append(gate_id)
            self.spl_gates_active.append(gate_id)
        try:
            lines_read = self.reader.read(**kwargs)
        except Exception as e:
            log.error(e)
            return False
        if not gate_ids:
            if lines_read:
                log.warning(
                    'Discarding serial messages, no gate locks! ({})'\
                    .format(lines_read)
                )
            return False
        # [ NOTE ]: Alpha version (POC) will only handle one primary gate lock
        #           pin at a time. Newer locks have priority over known but yet
        #           unreleased locks.
        primary_gate_id = gate_ids[0] if not new_ids else new_ids[0]
        if not sys_path or not gate_ids:
            return False
        if (target == 'file' and not check_file_exists(sys_path)) or \
                (target == 'pipe' and not check_is_fifo(sys_path)):
            return False

        if not lines_read:
            log.debug('No serial messages to read.')
            return False
        log.debug('Serial transmission: ({})'.format(lines_read))
        with open(sys_path, 'a') as fl:
            for msg_line in lines_read:
                log.debug('Writing instruction to FIFO: ({}) ({})'.format(
                    sys_path, msg_line
                ))
                fl.write(
                    str(msg_line).lstrip("b'").rstrip("'")
                    + ',' + str(gate_id) + ';\n'
                )
        update = self.update_message_archive(
            primary_gate_id, timestamp=datetime.datetime.now(), direction='IN',
            message=''.join(lines_read)
        )
        return sys_path

    def read2pipe(self, fifo_path, **kwargs):
        log.debug('')
        if not check_is_fifo(fifo_path):
            log.warning(
                'No SPL interpreter FIFO pipe found! Creating... ({})'.format(
                    fifo_path
                )
            )
            try:
                os.mkfifo(fifo_path)
            except Exception as e:
                log.error(e)
                return False
        if kwargs.get('endless') is False:
            return self.read2disk(fifo_path, target='pipe', **kwargs)
        try:
            while True:
                self.read2disk(fifo_path, target='pipe', **kwargs)
        finally:
            self.cleanup()

    def read2file(self, file_path, **kwargs):
        log.debug('')
        if not check_file_exists(file_path):
            log.warning(
                'No SPL interpreter message dump file found! Creating... ({})'.format(
                    file_path
                )
            )
            try:
                os.system('touch ' + file_path)
            except Exception as e:
                log.error(e)
                return False
        if kwargs.get('endless') is False:
            return self.read2disk(file_path, target='file', **kwargs)
        try:
            while True:
                self.read2disk(file_path, target='file', **kwargs)
        finally:
            self.cleanup()

    def write(self, *args, **kwargs):
        '''
        [ NOTE ]: *args are lines that are to be written to serial bus
        [ NOTE ]: **kwargs contains information on how to process the instruction
        '''
        log.debug('')
        return self.writer.write(*args, **kwargs)

    def read(self, **kwargs):
        '''
        [ NOTE ]: **kwargs contains information on how to process the instruction
        '''
        log.debug('')
        return self.reader.read(**kwargs)

    # SETUP

    def setup_gpio_pins(self):
        log.debug('')
        GPIO.setwarnings(self.pi_warnings)
        if not self.spl_gate_pins:
            return False
        GPIO.setmode(self.gpio_mode)
        for gate_id in self.spl_gate_pins:
            GPIO.setup(self.spl_gate_pins[gate_id], GPIO.OUT)
        return True

    # CLEANUP

    def cleanup_spl_active_gate_locks_cache(self):
        log.debug('')
        to_remove = [
            gate_id for gate_id in self.spl_gates_active
            if GPIO.input(self.spl_gate_pins[gate_id]) == 0
        ]
        log.debug('Removing gate locks from cache: ({})'.format(to_remove))
        for gate_id in to_remove:
            log.debug('Removing... ({})'.format(gate_id))
            self.spl_gates_active.remove(gate_id)
        return True

    def cleanup(self):
        log.debug('')
        return {
            'spl-reader': self.reader.port_cnx.close(),
            'spl-writer': self.writer.port_cnx.close(),
            'spl-active': self.cleanup_spl_active_gate_locks_cache(),
            'rpi-gpio': GPIO.cleanup(),
        }

    # MAGIK

    def __str__(self):
        return '{} {} {}'.format(self.serial_ports, self.reader, self.writer)


if __name__ == '__main__':

    spl = SPL('/dev/serial0')
    spl.write('first line\n', 'second line\n')
    spl.read2pipe('/tmp/spl-test1')
    spl.interpret('SPLT:Serial,Power,Link,Transmission;')

# CODE DUMP

