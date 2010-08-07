import datetime
import sys
import threading

import wx

import lumos.buddy_summary
import lumos.util
import lumos.view.main_frame

class Lumos(wx.App):

    def __init__(self, redirect, debug):
        wx.App.__init__(self, redirect)

        self.debug = debug

        thread = threading.Thread(target=lumos.util.update_database,
                                  args=[self.on_db_updated])
        thread.setDaemon(True)
        thread.start()

    # Initialization overriding wx.App's __init__ method
    def OnInit(self):
        conn = lumos.util.get_connection()
        user_id = lumos.util.get_user_id(conn, lumos.util.get_current_sn())

        self.frame = lumos.view.main_frame.MainFrame(self,
            lumos.buddy_summary.get_all(conn, user_id))
        self.frame.Show()
        conn.close()
        return True

    def on_db_updated(self):
        print "UPDATED DATABASE!"
        self.conn = lumos.util.get_connection()
        user_id = lumos.util.get_user_id(self.conn, lumos.util.get_current_sn())
        self.frame.refresh_data(lumos.buddy_summary.get_all(self.conn, user_id))
        # evt.Skip()
