import sys
import datetime
import threading

import wx

from view.main_frame import MainFrame
import buddy_log_entry
import buddy_summary
import util

class Lumos(wx.App):

    def __init__(self, redirect, debug):
        wx.App.__init__(self, redirect)
        self.debug = debug

        thread = threading.Thread(target=util.update_database,
                                  args=[self.on_db_updated])
        thread.setDaemon(True)
        thread.start()

    # Initialization overriding wx.App's __init__ method
    def OnInit(self):
        conn = util.get_connection()
        user_id = util.get_user_id(conn, util.CURRENT_ACCT[-1])

        self.frame = MainFrame(self, buddy_summary.get_all(conn, user_id))
        self.frame.Show()
        conn.close()
        return True

    def on_db_updated(self):
        print "UPDATED DATABASE!"
        self.conn = util.get_connection()
        user_id = util.get_user_id(self.conn, util.CURRENT_ACCT[-1])
        self.frame.refresh_data(buddy_summary.get_all(self.conn, user_id))
        # evt.Skip()

if __name__ == '__main__':
    debug_val = ('-d' in sys.argv)
    l = Lumos(redirect=False, debug=debug_val)
    l.MainLoop()
