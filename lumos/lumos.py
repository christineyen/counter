import sqlite3
import os
import sys
from os.path import split, getsize, join, isfile
from shutil import copytree, rmtree
import datetime
import threading

import wx

from view.main_frame import MainFrame
from buddy_log_entry import *
from buddy_summary import *

class Lumos(wx.App):
    ACCTS = [['AIM', 'cyenatwork'], ['AIM', 'thensheburns'],
             ['GTalk','christineyen@gmail.com']]
    CURRENT_ACCT = ACCTS[0]
    path = os.path.join('/Users', 'cyen', 'Library', 'Application Support',
                        'Adium 2.0', 'Users', 'Default', 'LogsBackup',
                        '.'.join(CURRENT_ACCT))
    db_path = os.path.join('/Users', 'cyen', 'Library', 'Preferences', 'lumos',
                           'Local Store', 'db', '.'.join(CURRENT_ACCT)+'.db')
    acct_logs = os.listdir(path)

    def __init__(self, redirect, debug):
        wx.App.__init__(self, redirect)
        self.debug = debug
        thread = threading.Thread(target=self.update_database)
        thread.setDaemon(True)
        thread.start()

    # Initialization overriding wx.App's __init__ method
    def OnInit(self):
        conn = self.get_connection()
        user_id = get_user_id(conn, self.CURRENT_ACCT[-1])

        self.frame = MainFrame(self, get_all_buddy_summaries(conn, user_id))
        self.frame.Show()
        conn.close()
        return True

    def get_connection(self):
        if not os.path.exists(self.db_path):
            db_parent = os.path.dirname(self.db_path)
            if not os.path.exists(db_parent):
                os.makedirs(db_parent)
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        self.setup_db(conn)
        self.update_from_logs(conn)
        return conn

    def setup_db(self, conn):
        conn.executescript('''create table if not exists users
                           (id integer primary key, screenname text);''')
        conn.executescript('''create table if not exists conversations
                           (id integer primary key, user_id integer,
                           buddy_id integer, size integer, initiated boolean,
                           msgs_user integer, msgs_buddy integer,
                           start_time float, end_time float, timestamp float,
                           file_path string);''')
        conn.executescript('''create unique index if not exists user_start_time
                           on conversations(buddy_id, start_time, end_time);''')

    def on_db_updated(self):
        print "UPDATED DATABASE!"
        self.conn = self.get_connection()
        user_id = get_user_id(self.conn, self.CURRENT_ACCT[-1])
        self.frame.refresh_data(get_all_buddy_summaries(self.conn, user_id))
        # evt.Skip()

    def update_database(self):
        # todo: EARLY RETURN! find a way to check need for this
        conn = self.get_connection()
        self.convert_new_format()
        self.update_from_logs(conn)
        conn.close()
        wx.CallAfter(self.on_db_updated)

    def convert_new_format(self):
        """ Converts old *****.chatlog file to *****.chatlog/*****.xml format,
            removes .DS_Store fields """
        print '''Backing up your logs...''' + self.path
        return False # todo re-allow

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
                        os.renames(chatlog+'2',
                                   join(dir, fn, fn.rsplit('.',1)[0]+'.xml'))
            rmtree(self.path+'.bk')
        except OSError:
            print 'Backup already exists. Did the process not finish last time?'

    def update_from_logs(self, conn):
        for username in self.acct_logs:
            if username[0] == '.': continue
            cur = conn.cursor()
            cur.execute('''select max(timestamp) from conversations inner join
                        users on users.id = conversations.buddy_id where
                        users.screenname = ? limit 1''', (username,))
            ts = cur.fetchone()
            if ts is None:
                last_file_ts = 0
            else:
                last_file_ts = ts[0]

            if last_file_ts >= os.stat(join(self.path, username)).st_mtime:
                continue
            print 'updating db for '+username

            for root, dirs, files in os.walk(join(self.path, username)):
                if not files: continue # empty dir
                for name in files:
                    if name.find('.swp') > -1: continue
                    if last_file_ts >= os.stat(join(root, name)).st_mtime:
                        continue
                    create_buddy_log_entry(conn, self.CURRENT_ACCT[-1],
                                           username, join(root, name))

if __name__ == '__main__':
    debug_val = ('-d' in sys.argv)
    l = Lumos(redirect=False, debug=debug_val)
    l.MainLoop()
