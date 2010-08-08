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

    VIEW_TYPES = {
        'bytes': BYTES,
        'msgs': MSGS,
        'conversations': CONVERSATIONS
    }

    def __init__(self, parent, application):
        lumos.view.plotter.Plotter.__init__(self, parent, application)

        self.view_type = QuantityPlotter.BYTES

        options = QuantityOptions(self, pos=(0, 460))

        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 14, wx.EXPAND)
        self.sizer.Add(options, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

        self.Bind(lumos.events.EVT_QUANTITY_SETTINGS, self.on_settings_change)


    def update(self, buddy_sn_list):
        if len(buddy_sn_list) == 0: return self.draw_blank()
        self.current_buddy_sn_list = buddy_sn_list

        # todo: decide how we feel about the view looking stuff up in the db
        # todo: consider moving some of this elsewhere, triggered by events
        all_entries = self.fetch_log_entries_by_buddy(buddy_sn_list)

        self.figure.clear()
        self.figure.gca().clear()
        for buddy_entry_list in all_entries:
            if len(buddy_entry_list) == 0: continue
            buddy_sn = buddy_entry_list[0].buddy_sn

            x, y = self.data_by_type(buddy_entry_list)

            if self.app.debug:
                print '%d chats w/ %s' % (len(buddy_entry_list), buddy_sn)
                print 'x: ' + str(x)
                print 'y: ' + str(y)

            self.figure.gca().plot_date(dates.date2num(x), y, linestyle='-',
                marker='o', color=self.color_for_sn(buddy_sn))
        self.figure.legend(self.figure.gca().get_lines(), buddy_sn_list,
            'upper left', prop={'size': 'small'})

        self.figure.canvas.draw()

    def data_by_type(self, buddy_entry_list):
        x = []
        y = []

        for i, e in enumerate(buddy_entry_list):
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

        return x, y


    def on_settings_change(self, event):
        self.view_type = event.view_type
        print "self.view_type is now: " + str(self.view_type)
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

        self.Bind(wx.EVT_RADIOBUTTON, self.on_settings_change)

    def on_settings_change(self, event):
        view_type = event.EventObject.GetLabel()

        if view_type not in QuantityPlotter.VIEW_TYPES.keys():
            raise "unknown or null view type passed in!"

        view_type = QuantityPlotter.VIEW_TYPES.get(view_type)
        wx.PostEvent(self.GetParent(),
            lumos.events.QuantitySettingsEvent(self.GetId(), event, view_type))

