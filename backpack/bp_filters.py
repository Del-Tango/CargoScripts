#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# FILTERS

import os
import stat
import logging

log = logging.getLogger('')


def list_intersection(values1, values2):
    log.debug('')
    if not values1 or not values2:
        return False
    intersect = [item for item in values1 if item in values2]
    return intersect


def filter_file_name_from_path(file_path):
    log.debug('')
    return os.path.basename(file_path)


def filter_directory_from_path(file_path):
    log.debug('')
    return os.path.dirname(file_path)




