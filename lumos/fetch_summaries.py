"""A utility module to fetch the appropriate chunks of data from the sqlite db"""

import sqlite3
import datetime

sns_to_ids = {}

def get_cum_log_entries_for_user(conn, user_id, buddy_id, buddy_sn):
  cur = conn.cursor()
  cur.execute('SELECT * FROM conversations WHERE user_id=? AND buddy_id=?', (user_id, buddy_id))
  cumulative = {'size': 0, 'msgs_total': 0, 'msgs_user': 0}
  all_convs = []
  for row in cur:
    cumulative['size'] += row['size']
    cumulative['msgs_total'] += row['msgs_user'] + row['msgs_buddy']
    cumulative['msgs_user'] += row['msgs_user']

    all_convs.push({
      'buddy_sn': row['buddy_sn'],
      'size': cumulative['size'],
      'initiated': row['initiated'],
      'msgs_total': cumulative['msgs_total'],
      'msgs_user': cumulative['msgs_user'],
      'duration': row['end_time'] - row['start_time'],
      'date': row['start_time']})
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
