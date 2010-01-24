class BuddySummary(object):
  def __init__(self, size=-1, ct=-1, initated=0, buddy_id=-1, buddy_sn='', ts=None):
    self.size = size
    self.ct = ct
    self.initiated = initiated
    self.buddy_id = buddy_id
    self.buddy_sn = buddy_sn
    self.ts = ts

  def is_none(self):
    return (self.size < 0) and (self.ct < 0) and (self.initiated < 0) and
      (self.buddy_sn == '') and (self.ts is None)

  def to_string(self):
    return "BuddySummary for " + self.buddy_sn +
      "(id " + self.buddy_id + "), " + self.ct + " conversations taking up " + self.size +
      " bytes, last modified on " + self.ts.strftime('%D %H:%M:%S')
