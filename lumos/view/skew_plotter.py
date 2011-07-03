from matplotlib.ticker import MaxNLocator

import wx

import lumos.view.plotter

class SkewPlotter(lumos.view.plotter.Plotter):

    def __init__(self, parent):
        lumos.view.plotter.Plotter.__init__(
            self, parent, "Chat session initiator skew")
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

    def draw(self, buddy_sns=[], ble_entries=[]):
        ''' Draws a plot based on skew data.

            @param buddy_sns A list of strings representing buddy screen names.
            @param ble_entries A list of lists per buddy of BuddyLogEntrys.
            '''
        num_buddies = len(ble_entries)
        axes = self.figure.gca()
        for i, ble_list in enumerate(ble_entries):
            x, y_init, y_not_init = self.data(ble_list)

            # y_not_init is solid, y_init is not. legend points to solid

            color = self.color_for_sn(ble_list[0].buddy_sn)
            bar = axes.bar(x, y_not_init, color=color)
            axes.bar(x, y_init, edgecolor=color, color=(1, 1, 1))
        axes.set_ybound(-1, 1)
        self.figure.canvas.draw()

    def data(self, ble_list):
        y_init = [0] * len(ble_list)
        y_not_init = [0] * len(ble_list)
        for i, e in enumerate(ble_list):
            rat = float(e.msgs_buddy - e.msgs_user) / e.msg_ct()
            if e.initiated:
                y_init[i] = rat
            else:
                y_not_init[i] = rat
        return range(len(ble_list)), y_init, y_not_init

# OPTIONS: by initiation and by message count!
