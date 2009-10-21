import os
from os.path import split, getsize, join, isfile
import re
import math
from conversation import *
import sqlite3
from shutil import copytree
from Tkinter import *

class S:
  ACCTS = [['AIM', 'cyenatwork'], ['AIM', 'thensheburns'], ['GTalk','christineyen@gmail.com'], ['GTalk', 'temp']]
  CURRENT_ACCT = ACCTS[1]

  path = os.path.join('/Users', 'cyen', 'Library', 'Application Support', 'Adium 2.0', 'Users', 'Default', 'LogsBackup', '.'.join(CURRENT_ACCT))

  acct_logs = os.listdir(path)

  """ Converts old *****.chatlog file to *****.chatlog/*****.xml format,
      removes .DS_Store fields """
  def convert_new_format(self):
    print '''Backing up your logs...'''
    copytree(self.path, self.path+'.bk')
    print '''Converting chatlog structures...'''
    for username in self.acct_logs:
      if username == '.DS_Store': continue
      for dir_entry in os.listdir(join(self.path, username)):
        chatlog = join(self.path, username, dir_entry)
        if dir_entry == '.DS_Store': os.remove(chatlog); continue
        if isfile(chatlog):
          dir, fn = split(chatlog)
          os.rename(chatlog, chatlog+'2')
          os.renames(chatlog+'2', join(dir, fn, fn.rsplit('.',1)[0]+'.xml'))
    c = sqlite3.connect('db/' + '.'.join(self.CURRENT_ACCT))
    c.executescript('''drop table if exists users; create table users
      (id integer primary key, screenname text);''')
    c.executescript('''drop table if exists conversations; create table conversations
      (id integer primary key, user_id integer, buddy_id integer,
      byte_size integer, disk_size integer,
      msgs_user integer, msgs_buddy integer, time datetime);''')

  def print_summary(self):
    dict = {}
    for username in self.acct_logs:
      ct = size = disksize = 0
      for root, dirs, files in os.walk(join(self.path, username)):
        if not files: continue
        ct += len(files)
        size += sum(getsize(join(root, name)) for name in files)
        disksize += sum(get_block_size(join(root, name)) for name in files)
        for file in files:
          c = Conversation(self.CURRENT_ACCT, username, join(root, file))
          print username, c.time.strftime('%D %I:%M:%S %p')
      dict[username] = (ct, size, disksize)
      print username, '\t\t\t', ct, size, disksize

  def run(self):
    window = Tk()
    window.title('harroooo')
    window.mainloop()

s = S()
s.run()
# s.convert_new_format()
