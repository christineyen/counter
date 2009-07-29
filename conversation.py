from BeautifulSoup import BeautifulStoneSoup
from os.path import getsize
from dateutil.parser import *
import math
import sqlite3

def get_block_size(path):
  return int(math.ceil((getsize(path) / 1024.0) / 4) * 4)

class Conversation(object):
  def __init__(self, acct, buddy_sn, file_nm):
    print acct
    self.conn = sqlite3.connect('db/' + '.'.join(acct))
    self.parse(acct[-1], buddy_sn, file_nm)
    self.save()

  def parse(self, screen_name, buddy_sn, file_nm):
    cur = self.conn.cursor()
    cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (screen_name,))
    self.user = cur.fetchone()[0]

    cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (buddy_sn,))
    self.buddy = cur.fetchone()[0]

    self.size = getsize(file_nm)
    self.block_size = get_block_size(file_nm)
    xml = BeautifulStoneSoup(open(file_nm, 'r'))
    msgs = len(xml('message'))
    self.my_msgs = len(xml.findAll({'message': True}, {'sender': screenname}))
    self.their_msgs = msgs-self.my_msgs

    evt = xml.find({'event': True}, {'type': 'windowOpened'})
    self.time = parse(evt['time'].replace('.', ':'))
    # self.time = self.time.tzinfo.fromutc(self.time)

  def save(self):
    for itm in ['user', 'buddy', 'size', 'block_size', 'my_msgs', 'their_msgs', 'time']:
      assert getattr(self, itm, False)
    self.conn.execute('''INSERT INTO conversations (user_id, buddy_id,
      byte_size, disk_size, msgs_user, msgs_buddy, time) VALUES ?''',
      (self.user, self.buddy, self.size, self.block_size,
      self.my_msgs, self.their_msgs, self.time))
