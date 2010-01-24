#
#  conversation.py
#  alohomora
#
#  Created by christine on 8/9/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

from Foundation import *
import objc
from BeautifulSoup import BeautifulStoneSoup
import os
from dateutil.parser import *
import datetime
import math
import sqlite3

def get_block_size(size):
  return int(math.ceil((size / 1024.0) / 4) * 4)

class Conversation(object):
  def __init__(self, screen_name, conn, buddy_sn, file_nm):
    self.conn = conn
    self.user = self.get_user(screen_name)
    self.buddy = self.get_user(buddy_sn)

    stats = os.stat(file_nm)
    self.size = stats.st_size
    self.block_size = get_block_size(self.size)
    self.ts = stats.st_ctime
    
    xml = BeautifulStoneSoup(open(file_nm, 'r'))
    msgs = xml('message')
    if len(msgs) > 0:
      self.my_msgs = len(xml.findAll({'message': True}, {'sender': screen_name}))
      self.their_msgs = len(msgs)-self.my_msgs

      # evt = xml.find({'event': True}, {'type': 'windowOpened'})
      self.time = parse(msgs[0]['time'].replace('.', ':'))
      self.end_time = parse(msgs[-1]['time'].replace('.', ':'))
      self.save()
      # self.time = self.time.tzinfo.fromutc(self.time)
    
  def get_user(self, screen_name):
    cur = self.conn.cursor()
    cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (screen_name,))
    id = cur.fetchone()
    if id is None:
      cur.execute('INSERT INTO users (screenname) VALUES (?)', (screen_name,))
      cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (screen_name,))
    else: id = id[0]
    return id or cur.fetchone()[0]

  def save(self):
    for itm in ['user', 'buddy', 'size', 'block_size', 'my_msgs', 'their_msgs', 'time', 'end_time']:
      assert getattr(self, itm, False) is not None
    cur = self.conn.cursor()
    cur.execute('''INSERT INTO conversations (user_id, buddy_id,
      byte_size, disk_size, msgs_user, msgs_buddy, start_time, end_time, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      (self.user, self.buddy, self.size, self.block_size,
      self.my_msgs, self.their_msgs, self.time.strftime('%D %H:%M:%S'), self.end_time.strftime('%D %H:%M:%S'),
      datetime.datetime.now().strftime('%D %H:%M:%S')))
    self.conn.commit()
