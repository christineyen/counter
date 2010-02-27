import wx
from buddy_list import BuddyListCtrl
from chat_log_plotter import ChatLogPlotter
from jpg_icon import JpgIcon

class MainFrame(wx.Frame):
  def __init__(self, app, all_data):
    wx.Frame.__init__(self, None, -1, 'simpleeeee', None, wx.Size(780,540))

    self.CreateStatusBar()
    self.tbicon = JpgIcon(self)
    self.Bind(wx.EVT_CLOSE, self.on_close_window)

    box = wx.BoxSizer(wx.HORIZONTAL)
    plotter = ChatLogPlotter(self, app)
    # list nonsense
    data = [(bs.buddy_sn, bs.size, bs.start_time.ctime()) for bs in all_data]
    lst = BuddyListCtrl(self, data, plotter)
    box.Add(lst, 2, wx.EXPAND | wx.ALL, 3)

    box.Add(plotter, 3, wx.EXPAND)

    self.SetSizer(box)

    self.Center()

  def on_close_window(self, evt):
    self.tbicon.Destroy()
    evt.Skip()
