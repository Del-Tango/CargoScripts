#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# COMPUTERS

import logging

log = logging.getLogger('')


def compute_percentage(percentage, value):
    log.debug('')
    return (float(value) / 100) * float(percentage)


def compute_percentage_of(part, whole):
    log.debug('')
    try:
        if part == 0:
            percentage = 0
        else:
            percentage = 100 * float(part) / float(whole)
        return percentage #"{:.0f}".format(percentage)
    except Exception as e:
        percentage = 100
        return percentage #"{:.0f}".format(percentage)


