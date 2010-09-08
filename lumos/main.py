import datetime
import os
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

        thread = threading.Thread(target=self.util.update_database,
                                  args=[self.on_db_updated])
        thread.setDaemon(True)
        thread.start()

    # Initialization overriding wx.App's __init__ method
    def OnInit(self):
        self.frame = lumos.view.main_frame.MainFrame(self, [])
        self.util = lumos.util.Util(self.frame)

        self.frame.Show()
        return True

    def on_db_updated(self):
        new_util = lumos.util.Util(self.frame)
        conn = new_util.get_connection()

        user_id = new_util.get_user_id(new_util.get_current_sn())

        self.frame.refresh_data(lumos.buddy_summary.get_all(conn, user_id))
        new_util.close_connection()

