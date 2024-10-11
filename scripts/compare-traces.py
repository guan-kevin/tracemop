#!/usr/bin/env python3

import os
import sys


EVENTS_MAP = {}

def read_events_map():
    global EVENTS_MAP
    with open('events_encoding_id.txt') as f:
        for line in f.readlines():
            line = line.strip().split(',')
            if len(line) == 3:
                EVENTS_MAP['e{}'.format(line[2])] = line[1]


def read_locations(locations_txt):
    locations = {}
    header = False
    with open(locations_txt) as f:
        for line in f.readlines():
            if not header:
                header = True
                continue
            line = line.strip()
            if line:
                id, _, code = line.partition(' ')
                locations[id] = code[:code.index(')') + 1]
    return locations


def is_event_id(name):
    return name[0] == 'e' and name[1] in [str(i) for i in range(0, 10)]


def read_unique_traces(traces_txt, convert=None):
    has_id = False
    traces = {}  # Map trace to frequency
    header = False
    convert_event = 1 # 1 is unsure, 2 is sure, 0 is no
    with open(traces_txt) as f:
        for line in f.readlines():
            line = line.strip()
            if line:
                if not header:
                    header = True
                    if 'WITH ID' in line:
                        has_id = True
                    continue

                if has_id:
                    # line is trace-id trace-frequency trace
                    _, _, line = line.partition(' ')
                freq, _, trace = line.partition(' ')
                if convert is not None:
                    t = trace[1:-1] # Turn "[a~1, b~2]" to "a~1, b~2"
                    new_trace = []
                    for e in t.split(', '):
                        e_name, _, e_loc_freq = e.partition('~')

                        if has_id and convert_event > 0:
                            # need to convert ID (e.g., e1, e2, etc.) to spec event name (e.g., has_next, next)
                            if convert_event == 1:
                                convert_event = 2 if is_event_id(e_name) else 0
                                if convert_event == 2:
                                    e_name = EVENTS_MAP[e_name]
                            else:
                                e_name = EVENTS_MAP[e_name]

                        e_loc, _, e_freq = e_loc_freq.partition('x')
                        if not e_freq:
                            e_freq = 1
                        for actual_short, global_short in convert.items():
                            if actual_short == e_loc:
                                if e_freq == 1:
                                    new_trace.append('{}~{}'.format(e_name, global_short))
                                else:
                                    e_name = '{}~{}'.format(e_name, global_short)
                                    for i in range(int(e_freq)):
                                        new_trace.append(e_name)
                                break
                    traces['[' + ', '.join(new_trace) + ']'] = traces.get('[' + ', '.join(new_trace) + ']', 0) + int(freq)
                    continue
                else:
                    t = trace[1:-1] # Turn "[a~1, b~2]" to "a~1, b~2"
                    new_trace = []
                    for e in t.split(', '):
                        e_name, _, e_loc_freq = e.partition('~')
                        
                        if has_id and convert_event > 0:
                            # need to convert ID (e.g., e1, e2, etc.) to spec event name (e.g., has_next, next)
                            if convert_event == 1:
                                convert_event = 2 if is_event_id(e_name) else 0
                                if convert_event == 2:
                                    e_name = EVENTS_MAP[e_name]
                            else:
                                e_name = EVENTS_MAP[e_name]
                            
                        e_loc, _, e_freq = e_loc_freq.partition('x')
                        if not e_freq:
                            new_trace.append('{}~{}'.format(e_name, e_loc))
                        else:
                            e_name = '{}~{}'.format(e_name, e_loc)
                            for i in range(int(e_freq)):
                                new_trace.append(e_name)
                    traces['[' + ', '.join(new_trace) + ']'] = traces.get('[' + ', '.join(new_trace) + ']', 0) + int(freq)
                    continue
    return traces
                

def compare(actual, expected):
    actual_locations = read_locations(os.path.join(actual, 'locations.txt'))
    expected_locations = read_locations(os.path.join(expected, 'locations.txt'))
    if list(sorted(actual_locations.values())) != list(sorted(expected_locations.values())):
        print('ERROR:\t\tLocations don\'t match')
        exit(1)
    
    # Create a single location map
    global_location = {} # Long location to global short location
    actual_short_to_global = {} # Actual locations' short location to expected's short location
    for short, long in expected_locations.items():
        global_location[long] = short
      
    for short, long in actual_locations.items():
        # If long is xxx, short is y, and global_location[xxx] is z
        # It means in expected_locations, z points to xxx
        # So we want to convert actual_locations such that z points to xxx a well
        actual_short_to_global[short] = global_location[long]  # This will map y to z


    actual_traces = read_unique_traces(os.path.join(actual, 'unique-traces.txt'), actual_short_to_global)
    expected_traces = read_unique_traces(os.path.join(expected, 'unique-traces.txt'))

    for expected_trace, expected_frequency in expected_traces.items():
        if expected_trace not in actual_traces:
            print('ERROR:\t\t{} is in expected ({} times) but not actual'.format(expected_trace, expected_frequency))
        elif expected_frequency != actual_traces[expected_trace]:
            print('WARNING:\t\t{}\'s frequency is {} in expected, but is {} in actual'.format(expected_trace, expected_frequency, actual_traces[expected_trace]))
    for actual_trace, actual_frequency in actual_traces.items():
        if actual_trace not in expected_traces:
            print('ERROR:\t\t{} is in actual ({} times) but not expected'.format(actual_trace, actual_frequency))
        


def main(argv=None):
    argv = argv or sys.argv

    if len(argv) < 3:
        print('Usage: python3 compare-traces.py <actual-traces-dir> <expected-traces-dir>')
        exit(1)
    actual = argv[1]
    expected = argv[2]

    if not os.path.exists(os.path.join(actual, 'locations.txt')) or not os.path.exists(os.path.join(expected, 'locations.txt')):
        print('Cannot find locations.txt')
        exit(1)
    
    if not os.path.exists(os.path.join(actual, 'unique-traces.txt')) or not os.path.exists(os.path.join(expected, 'unique-traces.txt')):
        print('Cannot find unique-traces.txt')
        exit(1)

    read_events_map()
    compare(actual, expected)


if __name__ == '__main__':
    main()
