#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# CONVERTORS

import json
import logging
import os
import base64

log = logging.getLogger('')


def encode_message_base64(message):
    base64_bytes = base64.b64encode(message_bytes)
    base64_message = base64_bytes.decode('ascii')
    return base64_message


def decode_message_base64(base64_message):
    if not isinstance(base64_message, str):
        return False
    base64_bytes = base64_message.encode('ascii')
    message_bytes = base64.b64decode(base64_bytes)


def json2dict(file_path):
    if not file_path or not os.path.exists(file_path):
        log.warning('File not found! ({})'.format(file_path))
        return {}
    with open(file_path, 'r') as fl:
        converted = json.load(fl)
    log.debug('Converted JSON: ({})'.format(converted))
    return converted


def dict2json(dict_obj):
    if not dict_obj:
        log.warning('No data to convert! ({})'.format(dict_obj))
        return {}
    converted = json.dumps(dict_obj, indent=4)
    log.debug('Converted JSON: ({})'.format(converted))
    return converted


def file2list(file_path):
    if not file_path or not os.path.exists(file_path):
        log.warning('File not found! ({})'.format(file_path))
        return {}
    with open(file_path, 'r') as fl:
        converted = fl.readlines()
    log.debug('Lines read from file: ({})'.format(converted))
    return converted
