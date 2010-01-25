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
from util import get_user_id
import time
from datetime import datetime

def get_cum_log_entries_for_user(conn, user_id, buddy_id, buddy_sn):
  """Gets the full list of log entries for a given user - each BuddyLogEntry in the list
     represents an individual conversation"""
  cur = conn.cursor()
  cur.execute('SELECT * FROM conversations WHERE user_id=? AND buddy_id=?', (user_id, buddy_id))
  cumulative = {'size': 0, 'msgs_buddy': 0, 'msgs_user': 0}
  all_convs = []
  for row in cur:
    cumulative['size'] += row['size']
    cumulative['msgs_buddy'] += row['msgs_buddy']
    cumulative['msgs_user'] += row['msgs_user']

    all_convs.append(BuddyLogEntry(user_id, buddy_sn, buddy_id, cumulative['size'], row['initiated'],
      cumulative['msgs_user'], cumulative['msgs_buddy'], row['start_time'], row['end_time'], None))
  return all_convs

def get_all_log_entries_for_user(conn, user_id, buddy_id, buddy_sn):
  """not actually used anywhere, deprecated in favor of get_cumu_for_user"""
  cur = conn.cursor()
  cur.execute('SELECT * FROM conversations WHERE user_id=? AND buddy_id=?', (user_id, buddy_id))
  all_convs = []
  for row in cur:
    all_convs.append({
      'buddy_sn': row['buddy_sn'],
      'size': row['size'],
      'initiated': row['initiated'],
      'msgs_total': row['msgs_user'] + row['msgs_buddy'],
      'msgs_user': row['msgs_user'],
      'duration': row['end_time'] - row['start_time'],
      'date': row['start_time']})

  return all_convs

def create_buddy_log_entry(conn, user_sn, buddy_sn, file_nm):
  xml = BeautifulStoneSoup(open(file_nm, 'r'))
  msgs = xml('message')
  if len(msgs) == 0: return

  my_msgs = len(xml.findAll({'message': True}, {'sender': user_sn}))
  their_msgs = len(msgs)-my_msgs
  initiated = (msgs[0]['sender'] == user_sn)
  start_time = parse(msgs[0]['time'].replace('.', ':'))
  end_time = parse(msgs[-1]['time'].replace('.', ':'))

  user_id = get_user_id(conn, user_sn)
  buddy_id = get_user_id(conn, buddy_sn)
  stats = stat(file_nm)

  cur = conn.cursor()
  try:
    cur.execute('''INSERT INTO conversations (user_id, buddy_id,
      size, initiated, msgs_user, msgs_buddy, start_time, end_time, timestamp, file_path) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      (user_id, buddy_id, stats.st_size, initiated,
      my_msgs, their_msgs, time.mktime(start_time.timetuple()), time.mktime(end_time.timetuple()),
      time.time(), file_nm))
    conn.commit()
  except sqlite3.IntegrityError:
    pass

class BuddyLogEntry(object):
  """A simple object to represent a single chat log"""
  def __init__(self, user_id=-1, buddy_sn='', buddy_id=-1, size=-1, initiated=1, msgs_user=0, msgs_buddy=0, start_time=None, end_time=None, timestamp=None):
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

  def to_string(self):
    return '%s: %d bytes on %s\n' % (self.buddy_sn, self.size, datetime.fromtimestamp(self.start_time).ctime())
