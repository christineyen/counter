"""A utility module to fetch the appropriate chunks of data from the sqlite db"""
# todo: kill this module, stick methods somewhere that makes more sense

import sqlite3
import datetime

sns_to_ids = {}

def get_user_id(conn, screen_name):
  if screen_name in sns_to_ids: return sns_to_ids[screen_name]

  cur = conn.cursor()
  cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (screen_name,))
  row = cur.fetchone()
  if row is None:
    cur.execute('INSERT INTO users (screenname) VALUES (?)', (screen_name,))
    cur.execute('SELECT id FROM users WHERE screenname = ? LIMIT 1', (screen_name,))
    row = cur.fetchone()
  sns_to_ids[screen_name] = row[0]
  return row[0]
