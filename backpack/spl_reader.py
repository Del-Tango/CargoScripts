#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Serial Power Link Reader

import serial
import datetime
import pysnooper
import logging

log = logging.getLogger('')


class SPLReader(object):
    '''
    [ NOTE ]: Custom interface wrapper for the serial library
    '''

    def __init__(self, *args, **kwargs):
        self.port_cnx = kwargs.get('port_cnx', serial.Serial(
            args[0],
            baudrate=kwargs.get('baudrate', 115200),
            bytesize=kwargs.get('bytesize', 8),
            parity=kwargs.get('parity', 'N'),
            stopbits=kwargs.get('stopbits',1),
            timeout=kwargs.get('timeout', 3.0),
        ))
        self._last_message = list()
        self._timestamp = datetime.datetime.now()
        log.debug('SPL Reader object initialized!')

    def update_serial_read_timestamp(self):
        log.debug('')
        self._timestamp = datetime.datetime.now()
        return self._timestamp

    def read(self, **kwargs):
        log.debug('')
        try:
            self._last_message = [
                item.decode('utf8') for item in self.port_cnx.readlines()
            ]
        except Exception as e:
            log.error(e)
            return False
        if not self.update_serial_read_timestamp():
            log.error('Could not update serial read timestamp!')
            return False
        return self._last_message

    def __str__(self):
        return '{} - [{}]: {}'.format(
            self.port_cnx, self._timestamp, self._last_message
        )


