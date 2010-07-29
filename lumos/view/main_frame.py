import wx
from buddy_list import BuddyListCtrl
from chat_log_plotter import ChatLogPlotter
from display_options import DisplayOptions
from jpg_icon import JpgIcon

class MainFrame(wx.Frame):
    def __init__(self, app, all_data):
        wx.Frame.__init__(self, parent=None, title='simpleeeee',
            size=wx.Size(780,540))
        self.app = app

        self.CreateStatusBar()
        self.tbicon = JpgIcon(self)
        self.Bind(wx.EVT_CLOSE, self.on_close_window)

        hbox = wx.BoxSizer(wx.HORIZONTAL)
        # list nonsense
        vbox = wx.BoxSizer(wx.VERTICAL)
        self.plotter = ChatLogPlotter(self, self.app)
        # wx.StaticText(self, label="SOMETHING", pos=(310, 10))
        self.lst = BuddyListCtrl(self, self.plotter, size=(300, 450))
        self.load_data(all_data)
        options = DisplayOptions(self, self.plotter, pos=(0, 460))

        vbox.Add(self.lst, 14, wx.EXPAND | wx.ALL, 1)
        vbox.Add(options, 1, wx.EXPAND)

        hbox.Add(vbox, 2, wx.EXPAND | wx.ALL, 2)
        hbox.Add(self.plotter, 3, wx.EXPAND)

        self.SetSizer(hbox)

        self.Center

    def refresh_data(self, all_data):
        print "refresh data"
        # print "setting plotter to: " + str(self.plotter)
        self.load_data(all_data)

    def load_data(self, all_data):
        data = [(bs.buddy_sn, bs.size, bs.start_time.ctime())
                for bs in all_data]
        self.lst.update_data(data)

    def on_close_window(self, evt):
        self.tbicon.Destroy()
        evt.Skip()
