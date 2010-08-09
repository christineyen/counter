import wx

from lumos.events import EVT_LIST_ITEM_FOCUSED
from lumos.jpg_icon import JpgIcon
from lumos.view.buddy_list import BuddyListCtrl
from lumos.view.skew_plotter import SkewPlotter
from lumos.view.quantity_plotter import QuantityPlotter
from lumos.view.display_options import DisplayOptions

class MainFrame(wx.Frame):
    def __init__(self, app, all_data):
        wx.Frame.__init__(self, parent=None, title='simpleeeee',
            size=wx.Size(780,540))
        self.app = app

        self.CreateStatusBar()
        self.tbicon = JpgIcon(self)
        self.Bind(wx.EVT_CLOSE, self.on_close_window)

        hbox = wx.BoxSizer(wx.HORIZONTAL)

        self.lst = BuddyListCtrl(self, size=(300, 450))
        self.load_data(all_data)
        hbox.Add(self.lst, 2, wx.EXPAND | wx.ALL, 2)

        self.nb = self.setup_right_side()
        hbox.Add(self.nb, 3, wx.EXPAND)

        self.SetSizer(hbox)

        self.Center

        # BuddyList events
        self.Bind(EVT_LIST_ITEM_FOCUSED, self.on_item_focused)


    def setup_right_side(self):
        # Here we create the notebook and set up Panels as pages
        nb = wx.Notebook(self)
        quantity_plotter = QuantityPlotter(nb, self.app)
        skew_plotter = SkewPlotter(nb, self.app)

        nb.AddPage(quantity_plotter, "Quantity")
        nb.AddPage(wx.Panel(nb), "Time")
        nb.AddPage(skew_plotter, "Skew")

        return nb


    def refresh_data(self, all_data):
        print "refresh data"
        self.load_data(all_data)

    def load_data(self, all_data):
        data = [(bs.buddy_sn, bs.ct, bs.start_time.ctime())
                for bs in all_data]
        self.lst.update_data(data)

    def on_item_focused(self, evt):
        print "== main frame sees: event " + str(evt.__class__) + \
            ", " + str(evt.buddy_sns)
        self.nb.GetCurrentPage().update(evt.buddy_sns)

    def on_close_window(self, evt):
        self.tbicon.Destroy()
        evt.Skip()
