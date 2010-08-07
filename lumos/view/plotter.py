import wx
import wx.lib.plot as plot

import lumos.buddy_log_entry
import lumos.util

class Plotter(wx.Panel):

    def __init__(self, parent, application):
        wx.Panel.__init__(self, parent)
        self.app = application

        self.plotter = plot.PlotCanvas(self)
        self.label = wx.StaticText(self.plotter, label='', pos=(20,100))

        '''self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.plotter, 1, wx.EXPAND)
        self.SetSizer(self.sizer)'''

        self.draw_blank()
        self.current_buddy_sn_list = []

    def fetch_log_entries_by_buddy(self, buddy_sn_list):
        user_id = lumos.util.get_user_id(self.app.conn, lumos.util.get_current_sn())

        all_entries = []
        for buddy_sn in buddy_sn_list:
            buddy_id = lumos.util.get_user_id(self.app.conn, buddy_sn)
            entries = lumos.buddy_log_entry.get_cumu_logs_for_user(
                self.app.conn, user_id, buddy_id, buddy_sn)
            all_entries.append(entries)

        return all_entries


    def draw_blank(self):
        self.plotter.Disable()
        self.label.SetLabel(DRAW_BLANK_TEXT)
        self.label.Wrap(400)

    def get_min_max_for_axis(self, axis, data):
        idx = 0 if axis == 'x' else 1
        axis_data = [elt[idx] for elt in data]
        return [min(axis_data), max(axis_data)]

    def color_for_sn(self, buddy_sn):
        hsh = hash(buddy_sn)
        return wx.Color(hsh % 256, hsh / 256 % 256, hsh / 256 / 256 % 256)

DRAW_BLANK_TEXT= ''' You have not selected any conversations to graph. Please click on one or more buddy screen names on the left to see results graphed in this space. '''
