from datetime import datetime
from matplotlib import dates

import wx

import lumos.events
import lumos.view.plotter

class QuantityPlotter(lumos.view.plotter.Plotter):
    # ViewType
    BYTES = 0
    MSGS = 1
    CONVERSATIONS = 2

    # Used to map the label text to a ViewType.
    VIEW_TYPES = {
        'bytes': BYTES,
        'msgs': MSGS,
        'conversations': CONVERSATIONS
    }

    FORMATTER = dates.DateFormatter('%m/%y')

    def __init__(self, parent, application):
        lumos.view.plotter.Plotter.__init__(
            self, parent, application, "Quantity of logs accumulated over time")

        self.view_type = QuantityPlotter.BYTES

        options = QuantityOptions(self, pos=(0, 460))

        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 14, wx.EXPAND)
        self.sizer.Add(options, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

        self.Bind(lumos.events.EVT_QUANTITY_SETTINGS, self.on_settings_change)


    def draw(self, buddy_sns=[], ble_entries=[]):
        ''' Draws a plot based on the size of conversations. '''
        axes = self.figure.gca()
        for ble_list in ble_entries:
            if len(ble_list) == 0: continue
            x, y = self.data_by_type(ble_list)

            axes.plot_date(dates.date2num(x), y,
                linestyle='-',
                marker='o',
                color=self.color_for_sn(ble_list[0].buddy_sn))
        axes.get_xaxis().set_major_formatter(QuantityPlotter.FORMATTER)
        self.figure.legend(axes.get_lines(), buddy_sns, 'upper left',
            prop={'size': 'small'})
        self.figure.canvas.draw()

    def data_by_type(self, ble_list):
        ''' Returns lists  of x and y coordinates based on the current view_type.

            @param ble_list A list of BuddyLogEntrys for a given user.
            '''
        x = []; y = []
        for i, e in enumerate(ble_list):
            x.append(datetime.fromtimestamp(e.start_time))
            if self.view_type == QuantityPlotter.BYTES:
                y.append(e.size)
            elif self.view_type == QuantityPlotter.MSGS:
                y.append(e.msg_ct())
            elif self.view_type == QuantityPlotter.CONVERSATIONS:
                y.append(i)

        # add a point to connect it to the x axis
        x.insert(0, x[0])
        y.insert(0, 0)

        if self.app.debug: self.print_debug_info(ble_list, x, y)

        return x, y

    def on_settings_change(self, event):
        self.view_type = event.view_type
        print "QuantityPlotter.view_type is now: " + str(self.view_type)
        self.update(self.current_buddy_sn_list)


class QuantityOptions(wx.Panel):
    def __init__(self, parent, pos=None):
        """ TODO: gross, i wish these options didn't have to touch the plotter
            directly"""
        wx.Panel.__init__(self, parent)
        sizer = wx.BoxSizer(wx.HORIZONTAL)

        label = wx.StaticText(self, label='cumulative: ')
        sizer.Add(label, 1)

        type = 'bytes'
        bytes = wx.RadioButton(self, label=type, style=wx.RB_GROUP)
        bytes.SetValue(True)
        sizer.Add(bytes, 1)

        type = 'msgs'
        msgs = wx.RadioButton(self, label=type)
        sizer.Add(msgs, 1)

        type = 'conversations'
        conversations = wx.RadioButton(self, label=type)
        sizer.Add(conversations, 1)

        self.SetSizer(sizer)

        self.Bind(wx.EVT_RADIOBUTTON, self.on_options_settings_change)

    def on_options_settings_change(self, event):
        view_type = event.EventObject.GetLabel()

        if view_type not in QuantityPlotter.VIEW_TYPES.keys():
            raise "unknown or null view type passed in!"

        view_type = QuantityPlotter.VIEW_TYPES.get(view_type)
        wx.PostEvent(self.GetParent(),
            lumos.events.QuantitySettingsEvent(self.GetId(), event, view_type))

