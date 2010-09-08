import wx

from lumos.events import EVT_LIST_ITEM_FOCUSED
from lumos.jpg_icon import JpgIcon
from lumos.view.buddy_list import BuddyListCtrl
from lumos.view.quantity_plotter import QuantityPlotter
from lumos.view.skew_plotter import SkewPlotter
from lumos.view.time_plotter import TimePlotter
from lumos.view.display_options import DisplayOptions

class MainFrame(wx.Frame):
    def __init__(self, application, all_data):
        wx.Frame.__init__(self, parent=None,
            title='Counter - visualization for libpurple chat logs',
            size=wx.Size(780,540))
        self.app = application

        self.CreateStatusBar()
        self.tbicon = JpgIcon(self)
        self.Bind(wx.EVT_CLOSE, self.on_close_window)

        hbox = wx.BoxSizer(wx.HORIZONTAL)

        self.lst = BuddyListCtrl(self, size=(300, 450))
        self.load_data(all_data)
        hbox.Add(self.lst, 2, wx.EXPAND | wx.ALL)

        self.nb = self.setup_right_side()
        hbox.Add(self.nb, 3, wx.EXPAND)

        self.SetSizer(hbox)

        self.Center()

        # BuddyList events
        self.Bind(EVT_LIST_ITEM_FOCUSED, self.on_item_focused)
        self.Bind(wx.EVT_NOTEBOOK_PAGE_CHANGED, self.on_page_changed)


    def setup_right_side(self):
        # Here we create the notebook and set up Panels as pages
        nb = wx.Notebook(self)
        quantity_plotter = QuantityPlotter(nb, self.app)
        time_plotter = TimePlotter(nb)
        skew_plotter = SkewPlotter(nb)

        nb.AddPage(quantity_plotter, 'Quantity')
        nb.AddPage(time_plotter, 'Time')
        nb.AddPage(skew_plotter, 'Skew')

        return nb


    def refresh_data(self, all_data):
        print 'refresh data'
        self.load_data(all_data)

    def load_data(self, all_data):
        if len(all_data) == 0:
            data = [('Loading...', 0, 0)]
        else:
            data = [(bs.buddy_sn, bs.ct, bs.start_time)
                    for bs in all_data]
        self.lst.update_data(data)

    def on_item_focused(self, evt):
        print '== main frame sees: event ' + str(evt.__class__) + \
            ', ' + str(evt.buddy_sns)
        self.nb.GetCurrentPage().update(evt.buddy_sns)

    def on_page_changed(self, evt):
        print '== main frame sees: event ' + str(evt.__class__)
        # TODO: the correct way to pass the new page the selected buddy sns
        #       would be to subclass wx.Notebook and stuff our own data inside
        #       the wx.NOTEBOOK_PAGE_CHANGED event, the way we did with
        #       ITEM_FOCUSED.
        self.nb.GetCurrentPage().update(self.lst.get_selected_buddy_sns())

    def on_close_window(self, evt):
        self.tbicon.Destroy()
        evt.Skip()
