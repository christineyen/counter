import wx
from buddy_list import BuddyListCtrl
from chat_log_plotter import ChatLogPlotter
from display_options import DisplayOptions
from jpg_icon import JpgIcon

class MainFrame(wx.Frame):
    def __init__(self, app, all_data):
        wx.Frame.__init__(self, parent=None, title='simpleeeee',
            size=wx.Size(780,540))

        self.CreateStatusBar()
        self.tbicon = JpgIcon(self)
        self.Bind(wx.EVT_CLOSE, self.on_close_window)

        hbox = wx.BoxSizer(wx.HORIZONTAL)
        plotter = ChatLogPlotter(self, app)
        # list nonsense
        vbox = wx.BoxSizer(wx.VERTICAL)
        data = [(bs.buddy_sn, bs.size, bs.start_time.ctime()) for bs in
                all_data]
        lst = BuddyListCtrl(self, data, plotter)
        vbox.Add(lst, 14, wx.EXPAND | wx.ALL, 1)

        options = DisplayOptions(self, plotter)

        vbox.Add(options, 1, wx.EXPAND)

        hbox.Add(vbox, 2, wx.EXPAND | wx.ALL, 2)

        hbox.Add(plotter, 3, wx.EXPAND)

        self.SetSizer(hbox)

        self.Center

    def on_close_window(self, evt):
        self.tbicon.Destroy()
        evt.Skip()
