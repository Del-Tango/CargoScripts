#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# CHECKERS

import os
import stat
import logging
#import pysnooper

from src.backpack.bp_filters import list_intersection

log = logging.getLogger('')


#@pysnooper.snoop()
def check_value_set_crossover(values1, values2, **kwargs):
    '''
    [ INPUT ]: [1,2,3,4,5], [5,4,3,2,1]

    [ RETURN ]: {
        'flag': True,           # Crossover detected
        'start1': 1,            # values1[0] value
        'start2': 5,            # values2[0] value
        'end1': 5,              # values1[len(values1)-1] value
        'end2': 1,              # values2[len(values2)-1] value
        'crossovers': [3],      # List of positions where crossovers occur (indexes)
        'confirmed': True       # If after a crossover values continuously increase
        'direction1': 'down',
        'direction2': 'up',
    }
    '''
    log.debug('')
    if len(values1) != len(values2):
        return False

    return_dict = {
        'flag': False,
        'start1': values1[0],
        'start2': values2[0],
        'end1': values1[len(values1)-1],
        'end2': values2[len(values2)-1],
        'crossovers': [],
        'confirmed': False,
        'direction1': '',
        'direction2': ''
    }

    if return_dict['start1'] < return_dict['end1']:
        return_dict['direction1'] = 'up'
    elif return_dict['start1'] > return_dict['end1']:
        return_dict['direction1'] = 'down'

    if return_dict['start2'] < return_dict['end2']:
        return_dict['direction2'] = 'up'
    elif return_dict['start2'] > return_dict['end2']:
        return_dict['direction2'] = 'down'

    old_val1, old_val2, confirmed = None, None, 0
    for index in range(len(values1)):
        val1, val2 = values1[index], values2[index]
        if val1 == val2 \
                or (None not in [old_val1, old_val2] and (old_val1 < old_val2 \
                    and val1 > val2)) \
                or (None not in [old_val1, old_val2] and (old_val1 > old_val2 \
                    and val1 < val2)):
            if not return_dict['flag']:
                return_dict.update({
                    'flag': True,
                    'crossovers': return_dict['crossovers'] + [index],
                })
            continue
        elif val1 > val2 \
                and val1 > return_dict['start1'] and val1 > old_val1:
            confirmed += 1
        elif val1 < val2 \
                and val2 > return_dict['start2'] and val2 > old_val2:
            confirmed += 1
        old_val1, old_val2 = val1, val2
    return_dict['confirmed'] = False if not confirmed else True
    return return_dict


#@pysnooper.snoop()
def check_value_set_divergence_peaks(values1, values2,
                                     peak_distance=1, error_margin=1, **kwargs):
    '''
    [ NOTE ]: Value divergence is confirmed if -
        * Larger distance than peak_distance data points between top indexes
        * Match higher and lower peaks with a index +/-error_margin
        * values1 peaks increase over time
        * values2 peaks decrease over time
    '''
    log.debug('')
    convergence = check_value_set_convergence(values1, values2)
    return_dict = {
        'flag': False,
        'start1': convergence['start1'],
        'start2': convergence['start2'],
        'end1': convergence['end1'],
        'end2': convergence['end2'],
        'direction1': convergence['direction1'],
        'direction2': convergence['direction2'],
        'peaks': [],
        'peaks1': [],
        'peaks2': [],
    }
    if len(values1) != len(values2): # or not convergence['flag']:
        return return_dict
    confirmed, top1_index, top2_index = False, [], []
    # NOTE: Look for two divergence peaks
    if return_dict['direction1'] == 'up' \
            and return_dict['direction2'] == 'down':
        top1, top2 = sorted(values1)[-2:], sorted(values2)
        top2.reverse(); top2 = top2[-2:]
        top1_index = [
            item for item in range(len(values1)) if values1[item] in top1
        ] #[0]
        top2_index = [
            item for item in range(len(values2)) if values2[item] in top2
        ] #[0]
        top_index = list_intersection(top1_index, top2_index)
        return_dict.update({
            'peaks': top_index,
            'peaks1': top1_index,
            'peaks2': top2_index,
        })
        if not len(top_index) >= 2:
            return return_dict
        val1a, val1b, = values1[top_index[0]], values1[top_index[1]]
        val2a, val2b = values2[top_index[0]], values2[top_index[1]]
        confirmed = True \
            if top1_index[1] - top1_index[0] >= peak_distance \
            and top1_index[0] in [
                top2_index[0],
                top2_index[0] + error_margin,
                top2_index[0] - error_margin
            ] and val1b > val1a \
            and top2_index[1] - top2_index[0] >= peak_distance \
            and top1_index[1] in [
                top2_index[1],
                top2_index[1] + error_margin,
                top2_index[1] - error_margin
            ] and val2b < val2a else False
    return_dict.update({'flag': confirmed,})
    return return_dict


#@pysnooper.snoop()
def check_value_set_convergence_peaks(values1, values2,
                                      peak_distance=1, error_margin=1, **kwargs):
    '''
    [ NOTE ]: Value convergence is confirmed if -
        * Larger distance than 2 data points between top indexes
        * Match higher and lower peaks with a +/-1 index error margin
        * values1 peaks increase over time
        * values2 peaks decrease over time
    '''
    log.debug('')
    convergence = check_value_set_convergence(values1, values2)
    return_dict = {
        'flag': False,
        'start1': convergence['start1'],
        'start2': convergence['start2'],
        'end1': convergence['end1'],
        'end2': convergence['end2'],
        'direction1': convergence['direction1'],
        'direction2': convergence['direction2'],
        'peaks': [],
        'peaks1': [],
        'peaks2': [],
    }
    if len(values1) != len(values2): # or not convergence['flag']:
        return return_dict
    confirmed, top1_index, top2_index = False, [], []
    # NOTE: Look for two convergent peaks
    if return_dict['direction1'] == 'down' \
            and return_dict['direction2'] == 'up':
        top1, top2 = sorted(values1), sorted(values2)[-2:]
        top1.reverse(); top1 = top1[-2:]
        top1_index = [
            item for item in range(len(values1)) if values1[item] in top1
        ] #[0]
        top2_index = [
            item for item in range(len(values2)) if values2[item] in top2
        ] #[0]
        top_index = list_intersection(top1_index, top2_index)
        return_dict.update({
            'peaks': top_index,
            'peaks1': top1_index,
            'peaks2': top2_index,
        })
        if not len(top_index) >= 2:
            return return_dict
        val1a, val1b, = values1[top_index[0]], values1[top_index[1]]
        val2a, val2b = values2[top_index[0]], values2[top_index[1]]
        confirmed = True \
            if top1_index[1] - top1_index[0] >= peak_distance \
            and top1_index[0] in [
                top2_index[0],
                top2_index[0] + error_margin,
                top2_index[0] - error_margin
            ] and val1b < val1a \
            and top2_index[1] - top2_index[0] >= peak_distance \
            and top1_index[1] in [
                top2_index[1],
                top2_index[1] + error_margin,
                top2_index[1] - error_margin
            ] and val2b > val2a else False
    return_dict.update({'flag': confirmed,})
    return return_dict


#@pysnooper.snoop()
def check_value_set_convergence(values1, values2, **kwargs):
    log.debug('')
    if len(values1) != len(values2):
        return False
    return_dict = {
        'flag': False,
        'start1': values1[0],
        'start2': values2[0],
        'end1': values1[len(values1)-1],
        'end2': values2[len(values2)-1],
        'direction1': '',
        'direction2': ''
    }

    crossover = check_value_set_crossover(values1, values2)

    if return_dict['start1'] < return_dict['end1']:
        return_dict['direction1'] = 'up'
    elif return_dict['start1'] > return_dict['end1']:
        return_dict['direction1'] = 'down'

    if return_dict['start2'] < return_dict['end2']:
        return_dict['direction2'] = 'up'
    elif return_dict['start2'] > return_dict['end2']:
        return_dict['direction2'] = 'down'

    if return_dict['direction1'] == 'down' \
            and return_dict['direction2'] == 'up' \
            and return_dict['start1'] > return_dict['start2'] \
            and not crossover['flag']:
        return_dict['flag'] = True

    if return_dict['direction1'] == 'up' \
            and return_dict['direction2'] == 'down' \
            and return_dict['start1'] < return_dict['start2'] \
            and not crossover['flag']:
        return_dict['flag'] = True

    return return_dict


# @pysnooper.snoop()
def check_value_set_divergence(values1, values2, **kwargs):
    log.debug('')
    if len(values1) != len(values2):
        return False
    return_dict = {
        'flag': False,
        'start1': values1[0],
        'start2': values2[0],
        'end1': values1[len(values1)-1],
        'end2': values2[len(values2)-1],
        'direction1': '',
        'direction2': ''
    }

    crossover = check_value_set_crossover(values1, values2)

    if return_dict['start1'] < return_dict['end1']:
        return_dict['direction1'] = 'up'
    elif return_dict['start1'] > return_dict['end1']:
        return_dict['direction1'] = 'down'

    if return_dict['start2'] < return_dict['end2']:
        return_dict['direction2'] = 'up'
    elif return_dict['start2'] > return_dict['end2']:
        return_dict['direction2'] = 'down'

    if return_dict['direction1'] == 'up' \
            and return_dict['direction2'] == 'down' \
            and return_dict['start1'] > return_dict['start2'] \
            and not crossover['flag']:
        return_dict['flag'] = True

    if return_dict['direction1'] == 'down' \
            and return_dict['direction2'] == 'up' \
            and return_dict['start1'] < return_dict['start2'] \
            and not crossover['flag']:
        return_dict['flag'] = True

    return return_dict


def check_value_set_above(values1, values2, **kwargs):
    '''
    [ NOTE ]: Check if all the values from 1 are higher than the values in 2.
    '''
    log.debug('')
    return_dict = {
        'flag': False,
        'start1': values1[0],
        'start2': values2[0],
        'end1': values1[len(values1)-1],
        'end2': values2[len(values2)-1],
        'direction1': '',
        'direction2': '',
        'above': [],
        'below': [],
    }
    if len(values1) != len(values2):
        return return_dict

    if return_dict['start1'] < return_dict['end1']:
        return_dict['direction1'] = 'up'
    elif return_dict['start1'] > return_dict['end1']:
        return_dict['direction1'] = 'down'

    if return_dict['start2'] < return_dict['end2']:
        return_dict['direction2'] = 'up'
    elif return_dict['start2'] > return_dict['end2']:
        return_dict['direction2'] = 'down'

    above1, above2, failures = 0, 0, 0
    for index in range(len(values1)):
        if not values1[index] or not values2[index]:
            failures += 1
            continue
        if values1[index] > values2[index]:
            above1 += 1
        elif values1[index] < values2[index]:
            above2 += 1

    return_dict.update({
        'flag': False if above1 != len(values1) else True,
        'above': values1 if above1 > above2 else values2,
        'below': values1 if above1 < above2 else values2,
    })
    return return_dict


def check_value_set_below(values1, values2, **kwargs):
    '''
    [ NOTE ]: Check if all the values from 1 are lower than the values in 2.
    '''
    log.debug('')
    return_dict = {
        'flag': False,
        'start1': values1[0],
        'start2': values2[0],
        'end1': values1[len(values1)-1],
        'end2': values2[len(values2)-1],
        'direction1': '',
        'direction2': '',
        'above': [],
        'below': [],
    }
    if len(values1) != len(values2):
        return return_dict

    if return_dict['start1'] < return_dict['end1']:
        return_dict['direction1'] = 'up'
    elif return_dict['start1'] > return_dict['end1']:
        return_dict['direction1'] = 'down'

    if return_dict['start2'] < return_dict['end2']:
        return_dict['direction2'] = 'up'
    elif return_dict['start2'] > return_dict['end2']:
        return_dict['direction2'] = 'down'

    below1, below2, failures = 0, 0, 0
    for index in range(len(values1)):
        if not values1[index] or not values2[index]:
            failures += 1
            continue
        if values1[index] < values2[index]:
            below1 += 1
        elif values1[index] > values2[index]:
            below2 += 1

    return_dict.update({
        'flag': False if below1 != len(values1) else True,
        'above': values1 if below1 < below2 else values2,
        'below': values1 if below1 > below2 else values2,
    })
    return return_dict


def check_majority_in_set(value, value_set):
    log.debug('')
    counter = len([item for item in value_set if item == value])
    return True if counter >= (len(value_set) / 2) else False


def check_pid_running(pid):
    '''
    [ NOTE ]: Sending signal 0 to a PID will raise an OSError exception if the
              PID is not running and do nothing otherwise.
    '''
    log.debug('')
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True


def check_superuser():
    log.debug('')
    return False if os.geteuid() != 0 else True


def check_is_fifo(fifo_path):
    log.debug('')
    try:
        return stat.S_ISFIFO(os.stat(fifo_path).st_mode)
    except Exception as e:
        log.error(e)
        return None


def check_file_exists(file_path):
    log.debug('')
    try:
        return os.path.exists(file_path)
    except Exception as e:
        log.error(e)
        return None


# CODE DUMP

