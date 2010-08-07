"""A utility module to fetch the appropriate chunks of data from sqlite"""

import sqlite3
import datetime
import os
from os.path import split, getsize, join, isfile
from shutil import copytree, rmtree

import wx
import buddy_log_entry

sns_to_ids = {}
ACCTS = [['AIM', 'cyenatwork'], ['AIM', 'thensheburns'],
         ['GTalk','christineyen@gmail.com']]
CURRENT_ACCT = ACCTS[0]
path = os.path.join('/Users', 'cyen', 'Library', 'Application Support',
                    'Adium 2.0', 'Users', 'Default', 'LogsBackup',
                    '.'.join(CURRENT_ACCT))
db_path = os.path.join('/Users', 'cyen', 'Library', 'Preferences', 'lumos',
                       'Local Store', 'db', '.'.join(CURRENT_ACCT)+'.db')
acct_logs = os.listdir(path)

# cfg strings and settings
cfg = wx.Config('lumosconfig')
CFG_current_sn = 'current_sn'

def get_current_sn():
    if not cfg.Exists(CFG_current_sn):
        print "setting current_sn setting"
        cfg.Write(CFG_current_sn, ACCTS[0][-1])
    return cfg.Read(CFG_current_sn)

def get_user_id(conn, screen_name):
    if screen_name in sns_to_ids: return sns_to_ids[screen_name]

    cur = conn.cursor()
    cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1',
                (screen_name,))
    row = cur.fetchone()
    if row is None:
        cur.execute('INSERT INTO users (screenname) VALUES (?)', (screen_name,))
        cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1',
                    (screen_name,))
        row = cur.fetchone()
    sns_to_ids[screen_name] = row[0]
    return row[0]

def get_connection():
    if not os.path.exists(db_path):
        db_parent = os.path.dirname(db_path)
        if not os.path.exists(db_parent):
            os.makedirs(db_parent)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    setup_db(conn)
    update_from_logs(conn)
    return conn

def setup_db(conn):
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

def update_database(callback):
    # todo: EARLY RETURN! find a way to check need for this
    conn = get_connection()
    update_from_logs(conn)
    conn.close()
    wx.CallAfter(callback)


def update_from_logs(conn):
    """ Looks at the last processed conversation we have on this user, and
        grabs any updated log files if needed. """
    for username in acct_logs:
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

        if last_file_ts >= os.stat(join(path, username)).st_mtime:
            continue
        print 'updating db for '+username

        for root, dirs, files in os.walk(join(path, username)):
            if not files: continue # empty dir
            for name in files:
                if name.find('.swp') > -1: continue
                if last_file_ts >= os.stat(join(root, name)).st_mtime:
                    continue
                buddy_log_entry.create(conn, get_current_sn(),
                                       username, join(root, name))
