#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Serial Power Link Writer

import serial
import datetime
import pysnooper
import logging

log = logging.getLogger('')


class SPLWriter(object):
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
        log.debug('SPL Writer object initialized!')

    def update_serial_write_timestamp(self):
        log.debug('')
        self._timestamp = datetime.datetime.now()
        return self._timestamp

    def write(self, *args, **kwargs):
        log.debug('')
        last_msg = [str(item).encode('utf8') for item in args]
        try:
            write = self.port_cnx.writelines(
                [str(item).encode('utf8') for item in args]
            )
        except Exception as e:
            return False
        self._last_message = list(args)
        if not self.update_serial_write_timestamp():
            log.error('Could not update serial write timestamp!')
            return False
        return self._last_message

    def __str__(self):
        return '{} - [{}]: {}'.format(
            self.port_cnx, self._timestamp, self._last_message
        )



