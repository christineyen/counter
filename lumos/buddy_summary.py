from datetime import datetime

def get_all_buddy_summaries(conn, user_id):
  cur = conn.cursor()
  cur.execute('SELECT users.screenname as sn, buddy_id as bid, COUNT(buddy_id) AS ct, \
              SUM(size) AS sz, SUM(initiated) as initiated, MAX(start_time) AS ts \
              FROM conversations INNER JOIN users ON users.id = conversations.buddy_id \
              WHERE conversations.user_id = ? GROUP BY buddy_id', (user_id,))
  all = []
  for row in cur:
    initiated = row['initiated'] - (row['ct'] / 2) # todo - CHECK this?
    ts = datetime.fromtimestamp(row['ts'])
    # all.append(BuddySummary(row['sz'], row['ct'], initiated, row['bid'], row['sn'], ts))
    all.append((row['sn'], str(row['sz']), ts.ctime()))
  return all

class BuddySummary(object):
  def __init__(self, size=-1, ct=-1, initiated=0, buddy_id=-1, buddy_sn='', ts=None):
    self.size = size
    self.ct = ct
    self.initiated = initiated
    self.buddy_id = buddy_id
    self.buddy_sn = buddy_sn
    self.ts = ts

  def is_none(self):
    return (self.size < 0) and (self.ct < 0) and (self.initiated < 0) and (self.buddy_sn == '') and (self.ts is None)

  def to_string(self):
    return 'BuddySummary for %s (id %i), %i conversations taking up %d bytes, last modified on %s' % \
      (self.buddy_sn, self.buddy_id, self.ct, self.size, self.ts.strftime('%D %H:%M:%S'))
