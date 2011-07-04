#
#  buddy_log_entry.py
#  lumos
#
#  Created by christine on 01/23/2010.
#  Copyright (c) 2010 Christine Yen. All rights reserved.
#

from BeautifulSoup import BeautifulStoneSoup
from datetime import datetime
from dateutil.parser import parse
from os import stat
import sqlite3
import time

import lumos.util

def get_cumu_logs_for_all():
    ''' Get aggregate statistics across all BuddyLogEntrys.

        @return a list of ONE list, representing all data in the db.
    '''
    util = lumos.util.Util(None)
    conn = util.get_connection()
    user_id = util.get_user_id(util.get_current_sn())
    entries = get_cumu_logs_for_user(conn, user_id)
    util.close_connection()
    return [entries]


def get_cumu_logs_for_set(buddy_sns):
    ''' For each buddy_sn passed in via buddy_sns, return a list of
        BuddyLogEntrys.

        @param buddy_sns A list of strings representing buddy screen names.
        @return a list of lists, holding individual BuddyLogEntrys.
    '''
    # SUPER hacky - assumes the correct config exists and doesn't need
    # to be checked / populated via dialog on the frame!
    util = lumos.util.Util(None)
    conn = util.get_connection()
    user_id = util.get_user_id(util.get_current_sn())

    all_entries = []
    for buddy_sn in buddy_sns:
        buddy_id = util.get_user_id(buddy_sn)
        entries = get_cumu_logs_for_user(conn, user_id, buddy_id, buddy_sn)
        all_entries.append(entries)

    util.close_connection()
    return all_entries


def get_cumu_logs_for_user(conn, user_id, buddy_id=0, buddy_sn=''):
    ''' Gets the data (accumulated by time) of each conversation for a given
        user. The cumulative 'initiated' data is more positive the more the
        buddy initiated, and more negative the more you initiated.

        If this data is requested for all data (buddy_id == 0), then we not
        only select data from all conversations, but only return 50 reprentative
        data points for the entire set, to not overwhelm the GUI.
    '''
    all_users = (buddy_id == 0)
    cur = conn.cursor()
    if all_users:
        cur.execute('''SELECT * FROM conversations WHERE user_id=?
                    ORDER BY start_time''', (user_id,))
    else:
        cur.execute('SELECT * FROM conversations WHERE user_id=? AND buddy_id=?',
                    (user_id, buddy_id))
    list = []
    for row in cur:
        list.append(row_to_dictionary(row))

    coarse_intervals = (len(list) / 50) + 1
    cumu_size = cumu_msgs_ct = 0
    all_convs = []
    for i, entry in enumerate(list):
        cumu_size += entry['size']
        cumu_msgs_ct += entry['msgs_user'] + entry['msgs_buddy']
        initiated = entry['initiated'] and 1 or 0
        ble = BuddyLogEntry(user_id, buddy_sn, buddy_id,
                            cumu_size, initiated, cumu_msgs_ct,
                            entry['msgs_user'], entry['msgs_buddy'],
                            entry['start_time'], entry['end_time'],
                            None)
        if (not all_users) or (i % coarse_intervals == 0):
            all_convs.append(ble)
    return all_convs


def row_to_dictionary(row):
    ''' Wrap a sqlite3 row in a dictionary for easy access. '''
    return { 'size'       : row['size'],
             'msgs_buddy' : row['msgs_buddy'],
             'msgs_user'  : row['msgs_user'],
             'initiated'  : row['initiated'],
             'start_time' : row['start_time'],
             'end_time'   : row['end_time']
            }


def create(conn, user_sn, user_id, buddy_id, file_nm):
    ''' Take a filename, parse the XML, and insert it into the database.
        Stores most of the attributes raw, in order to do other sorts of
        processing later.
    '''
    xml = BeautifulStoneSoup(open(file_nm, 'r'))
    msgs = xml('message')
    if len(msgs) == 0: return

    my_msgs = len(xml.findAll({'message': True}, {'sender': user_sn}))
    their_msgs = len(msgs)-my_msgs
    initiated = (msgs[0]['sender'] == user_sn)

    start_time = parse(msgs[0]['time'].replace('.', ':'))
    end_time = parse(msgs[-1]['time'].replace('.', ':'))
    stats = stat(file_nm)

    cur = conn.cursor()
    try:
        cur.execute(CREATE_NEW_BUDDY_LOG_ENTRY_QUERY,
                    (user_id, buddy_id, stats.st_size, initiated, my_msgs,
                    their_msgs, time.mktime(start_time.timetuple()),
                    time.mktime(end_time.timetuple()), time.time(), file_nm))
        conn.commit()
    except sqlite3.IntegrityError:
        pass


CREATE_NEW_BUDDY_LOG_ENTRY_QUERY = '''
    INSERT INTO conversations (user_id, buddy_id,
        size, initiated, msgs_user, msgs_buddy, start_time,
        end_time, timestamp, file_path) VALUES (?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?) '''


class BuddyLogEntry(object):
    """A simple object to represent a single chat log"""
    def __init__(self, user_id=-1, buddy_sn='', buddy_id=-1, size=-1,
                 initiated=0, cumu_msgs_ct=0, msgs_user=0, msgs_buddy=0,
                 start_time=None, end_time=None, timestamp=None):
        self.user_id = user_id
        self.buddy_sn = buddy_sn
        self.buddy_id = buddy_id
        self.size = size
        self.initiated = initiated
        self.cumu_msgs_ct = cumu_msgs_ct
        self.msgs_user = msgs_user
        self.msgs_buddy = msgs_buddy
        self.start_time = start_time
        self.end_time = end_time
        self.timestamp = timestamp

    def duration(self):
        return self.end_time - self.start_time

    def msg_ct(self):
        return self.msgs_user + self.msgs_buddy

    def pretty_start_time(self):
        return datetime.fromtimestamp(self.start_time)

    def pretty_end_time(self):
        return datetime.fromtimestamp(self.end_time)

    def to_string(self):
        initiated_str = self.initiated and ', initiated' or ''
        return '%s: %d bytes on %s%s\n' % (self.buddy_sn, self.size,
               datetime.fromtimestamp(self.start_time).ctime(), initiated_str)
