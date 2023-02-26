#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# FETCHERS

import time
import datetime
import logging

log = logging.getLogger('')


def fetch_timestamp(*args):
    log.debug('')
    timestamp_format = '%d/%m/%Y-%H:%M:%S' if not args else args[0]
    now = datetime.datetime.now()
    return now.strftime(timestamp_format)


def fetch_time():
    log.debug('')
    return time.strftime('%H:%M:%S')


def fetch_full_time():
    log.debug('')
    return time.strftime('%H:%M:%S, %A %b %Y')
