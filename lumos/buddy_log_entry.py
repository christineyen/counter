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
from fetch_summaries import get_user_id
import time

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
