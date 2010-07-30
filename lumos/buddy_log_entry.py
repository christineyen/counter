#
#  buddy_log_entry.py
#  lumos
#
#  Created by christine on 01/23/2010.
#  Copyright (c) 2010 Christine Yen. All rights reserved.
#

import sqlite3
from BeautifulSoup import BeautifulStoneSoup
from dateutil.parser import parse
from os import stat
import util
import time
from datetime import datetime

""" Gets the data (accumulated by time) of each conversation for a given
    user. """
def get_cumu_logs_for_user(conn, user_id, buddy_id, buddy_sn):
    list = fetch_all_log_entries_for_user(conn, user_id, buddy_id, buddy_sn)

    cumu_size = cumu_msgs_buddy = cumu_msgs_user = 0
    all_convs = []
    for entry in list:
        cumu_size += entry['size']
        cumu_msgs_user += entry['msgs_user']
        cumu_msgs_buddy += entry['msgs_buddy']
        ble = BuddyLogEntry(user_id, buddy_sn, buddy_id,
                            cumu_size, entry['initiated'], cumu_msgs_user,
                            cumu_msgs_buddy, entry['start_time'],
                            entry['end_time'], None)
        all_convs.append(ble)
    return all_convs


""" Gets the raw data of each conversation for a given user """
def get_all_logs_for_user(conn, user_id, buddy_id, buddy_sn):
    list = fetch_all_log_entries_for_user(conn, user_id, buddy_id, buddy_sn)

    all_convs = []
    for entry in list:
        ble = BuddyLogEntry(user_id, buddy_sn, buddy_id, entry['size'],
                            entry['initiated'], entry['msgs_user'],
                            entry['msgs_buddy'], entry['start_time'],
                            entry['end_time'], None)
        all_convs.append(ble)
    return all_convs


""" Fetches the full list of conversations for a user.
    Returns a list of dictionaries, for easy wrapping."""
def fetch_all_log_entries_for_user(conn, user_id, buddy_id, buddy_sn):
    cur = conn.cursor()
    cur.execute('SELECT * FROM conversations WHERE user_id=? AND buddy_id=?',
                (user_id, buddy_id))
    all_convs = []
    for row in cur:
        entry = { 'size'       : row['size'],
                  'msgs_buddy' : row['msgs_buddy'],
                  'msgs_user'  : row['msgs_user'],
                  'initiated'  : row['initiated'],
                  'start_time' : row['start_time'],
                  'end_time'   : row['end_time']
                }
        all_convs.append(entry)
    return all_convs


""" Take a filename, parse the XML, and insert it into the database.
    Stores most of the attributes raw, in order to do other sorts of
    processing later.
    """
def create(conn, user_sn, buddy_sn, file_nm):
    xml = BeautifulStoneSoup(open(file_nm, 'r'))
    msgs = xml('message')
    if len(msgs) == 0: return

    my_msgs = len(xml.findAll({'message': True}, {'sender': user_sn}))
    their_msgs = len(msgs)-my_msgs
    initiated = (msgs[0]['sender'] == user_sn)
    start_time = parse(msgs[0]['time'].replace('.', ':'))
    end_time = parse(msgs[-1]['time'].replace('.', ':'))

    user_id = util.get_user_id(conn, user_sn)
    buddy_id = util.get_user_id(conn, buddy_sn)
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
                 initiated=1, msgs_user=0, msgs_buddy=0, start_time=None,
                 end_time=None, timestamp=None):
        self.user_id = user_id
        self.buddy_sn = buddy_sn
        self.buddy_id = buddy_id
        self.size = size
        self.initiated = initiated
        self.msgs_user = msgs_user
        self.msgs_buddy = msgs_buddy
        self.start_time = start_time
        self.end_time = end_time
        self.timestamp = timestamp

    def duration(self):
        return self.end_time - self.start_time

    def msgs_total(self):
        return self.msgs_user + self.msgs_buddy

    def pretty_start_time(self):
        return datetime.fromtimestamp(self.start_time)

    def pretty_end_time(self):
        return datetime.fromtimestamp(self.end_time)

    def to_string(self):
        return '%s: %d bytes on %s\n' % (self.buddy_sn, self.size,
               datetime.fromtimestamp(self.start_time).ctime())
