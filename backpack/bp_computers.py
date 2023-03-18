#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# COMPUTERS

import logging

log = logging.getLogger('')


def compute_percentage(whole, part, operation=None):
    """
    [ NOTE ]: If not operation is specified, it returns a value that represents
        the specified percentage of a given whole value -

    [ EXAMPLE ]:

        >>> compute_percentage(1000, 10)
        100

    [ NOTE ]: If the operation= keyword is specified, it returns a value with
        the percentage value added or subtracted

    [ EXAMPLE ]:

        >>> compute_percentage(1000, 10, operation='add')
        1100

        >>> compute_percentage(1000, 10, operation='subtract')
        900
    """
    if not operation:
        return (float(part)/100) * float(whole)
    if operation not in ['add', 'subtract']:
        log.error('Invalid operation specified! {}'.format(operation))
        return False
    elif operation == 'subtract':
        part *= -1  # Multiply by -1 to subtract instead of add.
    return float(whole) * (1 + float(part)/100)


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


