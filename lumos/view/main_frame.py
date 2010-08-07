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

        right_box, self.plotter = self.setup_right_side()

        self.lst = BuddyListCtrl(self, self.plotter, size=(300, 450))
        self.load_data(all_data)

        hbox.Add(self.lst, 2, wx.EXPAND | wx.ALL, 2)
        hbox.Add(right_box, 3, wx.EXPAND)

        self.SetSizer(hbox)

        self.Center


    def setup_right_side(self):
        right_box = wx.BoxSizer(wx.VERTICAL)

        # Here we create a panel and a notebook on the panel
        nb = wx.Notebook(self)

        plotter = ChatLogPlotter(nb, self.app)
        nb.AddPage(plotter, "Plotter")
        nb.AddPage(wx.Panel(nb), "empty panel")

        options = DisplayOptions(self, plotter, pos=(0, 460))

        right_box.Add(nb, 14, wx.EXPAND | wx.ALL, 1)
        right_box.Add(options, 1, wx.EXPAND)

        return right_box, plotter


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
