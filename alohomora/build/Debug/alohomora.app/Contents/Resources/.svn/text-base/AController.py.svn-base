#
#  AController.py
#  alohomora
#
#  Created by christine on 8/3/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

import objc
import os
from os.path import split, getsize, join, isfile
import re
import math
from conversation import *
import sqlite3
from shutil import copytree, rmtree
from Foundation import *

class AController(NSObject):
  ACCTS = [['AIM', 'cyenatwork'], ['AIM', 'thensheburns'], ['GTalk','christineyen@gmail.com'], ['GTalk', 'temp']]
  CURRENT_ACCT = ACCTS[0]
  path = os.path.join('/Users', 'cyen', 'Library', 'Application Support', 'Adium 2.0', 'Users', 'Default', 'LogsBackup', '.'.join(CURRENT_ACCT))
  acct_logs = os.listdir(path)

  tableView = objc.IBOutlet()
  textField = objc.IBOutlet()
  listView = objc.IBOutlet()
  arrayController = objc.IBOutlet()
  summary_dict = []
  listArrayController = objc.IBOutlet()
  buddies = []
  
  def init(self):
    self = super(AController, self).init()
    sqlfile = self.pathForFilename('db/' + '.'.join(self.CURRENT_ACCT))
    if not os.path.exists(sqlfile):
        os.mkdirs(os.path.dirname(sqlfile))
    self.conn = sqlite3.connect(sqlfile)
    self.convert_new_format()
    return self

  @objc.IBAction
  def search_(self,sender):
    search_value = self.textField.stringValue()
    lst = self.print_summary()
    self.summary_dict = [ NSDictionary.dictionaryWithDictionary_(x) for x in lst]
    self.arrayController.rearrangeObjects()
    self.listArrayController.rearrangeObjects()
  
  def tableViewSelectionDidChange_(self, sender):
    selectedObjs = self.arrayController.selectedObjects()
    if len(selectedObjs) == 0:
        NSLog(u"No selected row!")
        return
        
    row = selectedObjs[0]
    NSLog(row)

    
  """ Converts old *****.chatlog file to *****.chatlog/*****.xml format,
      removes .DS_Store fields """
  def convert_new_format(self):
    print '''Backing up your logs...''' + self.path
    try:
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
      self.conn.executescript('''drop table if exists users; create table users
        (id integer primary key, screenname text);''')
      self.conn.executescript('''drop table if exists conversations; create table conversations
        (id integer primary key, user_id integer, buddy_id integer,
        byte_size integer, disk_size integer,
        msgs_user integer, msgs_buddy integer,
        start_time datetime, end_time datetime, timestamp datetime);''')
      rmtree(self.path+'bk')
    except OSError:
      print '''Backup already exists. Did the process not finish last time?'''

  def print_summary(self):
    arr = []
    for username in self.acct_logs:
      self.buddies.append(str(username))
      dict = self.get_summary(username)
      if dict is not None:
        arr.append(dict)
    return arr
    
  def get_summary(self, username):
    dict = {'username': username}
    cur = self.conn.cursor()
    cur.execute('''select count(buddy_id), sum(byte_size), sum(disk_size), max(timestamp)
      from conversations inner join users on users.id = conversations.buddy_id
      where users.screenname = ? group by buddy_id limit 1''', (username,))
    ts = cur.fetchone()
    if ts is None or ts[-1] < os.stat(join(self.path, username)).st_mtime:
      dict['attrs'] = self.load_summary(username)
    else: dict['attrs'] = str(ts)
    return dict
    
  def load_summary(self, username):
    print 'calculating for ' + username
    ct = size = disksize = 0
    for root, dirs, files in os.walk(join(self.path, username)):
      if not files: continue
      ct += len(files)
      for name in files:
        sz = getsize(join(root, name))
        size += sz
        disksize += get_block_size(sz)
      for file in files:
        c = Conversation(self.CURRENT_ACCT[-1], self.conn, username, join(root, file))
    # self.conn.cursor().execute('select count(*) from conversations')
    # x = self.conn.cursor().fetchall()
    # if username != '.DS_Store' and len(x) == 0: raise RuntimeError
    return str((ct, size, disksize))
    
  def applicationSupportFolder(self):
    paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,True)
    basePath = (len(paths) > 0 and paths[0]) or NSTemporaryDirectory()
    fullPath = basePath.stringByAppendingPathComponent_("alohomora")
    if not os.path.exists(fullPath):
        os.mkdir(fullPath)
    return fullPath
  def pathForFilename(self,filename):
    return self.applicationSupportFolder().stringByAppendingPathComponent_(filename)
