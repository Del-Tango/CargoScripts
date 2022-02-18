import time
import logging

log = logging.getLogger('')

# FETCHERS


def fetch_time():
    log.debug('')
    return time.strftime('%H:%M:%S')


def fetch_full_time():
    log.debug('')
    return time.strftime('%H:%M:%S, %A %b %Y')
