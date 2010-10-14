"""A utility module to fetch the appropriate chunks of data from sqlite"""

import datetime
import os
from os.path import join
from shutil import copytree, rmtree
import sqlite3

import wx

import lumos.buddy_log_entry

class Util:

    CONFIG_NAME_PATH = 'logs_path'
    DEFAULT_DIR = '/Users/' + os.getlogin() + '/Library/Application Support'
    DEFAULT_DB_TMPL = '/Users/%s/Library/Preferences/lumos/Local Store/db/%s.db'
    DIALOG_MSG = '''Select the directory your libpurple logs live in.
        Examples - Adium stores logs by default at:
          ''' + DEFAULT_DIR + '''/Adium 2.0/Users/Default/Logs/...
    '''

    def __init__(self, frame):
        self.cfg = wx.Config('lumos')
        self.path = ''
        self.sns_to_ids = {}
        self.conn = None

        if self.cfg.Exists(Util.CONFIG_NAME_PATH):
            self.path = self.cfg.Read(Util.CONFIG_NAME_PATH)
        else:
            dlg = wx.DirDialog(frame, Util.DIALOG_MSG, Util.DEFAULT_DIR,
                wx.DD_DIR_MUST_EXIST)
            if dlg.ShowModal() == wx.ID_OK:
                self.path = dlg.GetPath()
                if self.is_logs_path_sane(self.path):
                    # Trust this path!
                    self.cfg.Write(Util.CONFIG_NAME_PATH, self.path)
        self.account_dirname = self.path.split('/')[-1]
        self.current_sn = self.path.split('.')[-1]

    def is_logs_path_sane(self, logs_path):
        logs_path_segments = logs_path.split('/')

        if len(logs_path.strip()) == 0:
            raise 'Logs path was not initialized - still set to empty string'
        elif len(logs_path_segments) < 2:
            raise 'Logs path looks invalid'
        elif len(logs_path_segments[-1].split('.')) < 2:
            raise 'Logs path doesn\'t look like it ends in a SERVICE.user format'
        elif not os.path.exists(logs_path):
            raise 'Logs path doesn\'t exist!'
        return True

    def get_current_sn(self):
        return self.current_sn

    def get_user_id(self, screen_name):
        if screen_name in self.sns_to_ids: return self.sns_to_ids[screen_name]
        conn = self.get_connection()

        cur = conn.cursor()
        cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1',
                    (screen_name,))
        row = cur.fetchone()
        if row is None:
            cur.execute('INSERT INTO users (screenname) VALUES (?)', (screen_name,))
            cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1',
                        (screen_name,))
            row = cur.fetchone()
        self.sns_to_ids[screen_name] = row[0]
        return row[0]

    def get_connection(self):
        if self.conn is not None:
            return self.conn

        db_path = Util.DEFAULT_DB_TMPL % (os.getlogin(), self.account_dirname)
        if not os.path.exists(db_path):
            db_parent = os.path.dirname(db_path)
            if not os.path.exists(db_parent):
                os.makedirs(db_parent)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self.setup_db()
        self.update_from_logs()
        return self.conn

    def close_connection(self):
        if self.conn is not None:
            self.conn.commit()
            self.conn.close()

    def setup_db(self):
        conn = self.get_connection()
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

    def update_database(self, callback):
        # todo: EARLY RETURN! find a way to check need for this
        self.update_from_logs()
        wx.CallAfter(callback)

    def update_from_logs(self):
        """ Looks at the last processed conversation we have on this user, and
            grabs any updated log files if needed. """
        conn = self.get_connection()

        for username in os.listdir(self.path):
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
                    user_id = self.get_user_id(self.get_current_sn())
                    buddy_id = self.get_user_id(username)
                    lumos.buddy_log_entry.create(conn, self.get_current_sn(),
                                           user_id, buddy_id, join(root, name))

