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
        for i, ble_list in enumerate(ble_entries):
            if len(ble_list) == 0: continue
            buddy_sn = ble_list[0].buddy_sn

            # add_subplot(): num_buddies rows, 1 column, i+1'th plot
            ax = self.figure.add_subplot(num_buddies, 1, i+1)
            x, y = self.data(ble_list)

            ax.set_title(buddy_sn)
            ax.plot(x, y, linestyle='-',
                marker='o', color=self.color_for_sn(buddy_sn))

        self.figure.canvas.draw()

    def data(self, ble_list):
        y = [e.initiated for e in ble_list]
        y.insert(0, 0)

        return range(len(y)), y

# OPTIONS: by initiation and by message count!
