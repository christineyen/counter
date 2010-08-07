import wx
import wx.lib.plot as plot

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
        self.sizer.Add(self.plotter, 14, wx.EXPAND)
        self.sizer.Add(options, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

        self.Bind(lumos.events.EVT_QUANTITY_SETTINGS, self.on_settings_change)


    def update(self, buddy_sn_list):
        if len(buddy_sn_list) == 0: return self.draw_blank()
        self.current_buddy_sn_list = buddy_sn_list

        # todo: decide how we feel about the view looking stuff up in the db
        # todo: consider moving some of this elsewhere, triggered by events
        all_entries = self.fetch_log_entries_by_buddy(buddy_sn_list)

        line_list = []
        all_coords = []
        for buddy_entry_list in all_entries:
            if len(buddy_entry_list) == 0: continue
            buddy_sn = buddy_entry_list[0].buddy_sn

            data = self.data_by_type(buddy_entry_list)

            if self.app.debug:
                print '%d chats under %s' % (len(buddy_entry_list), buddy_sn)
                for e in buddy_entry_list:
                    print e.to_string()
                print data

            if len(data) > 0 and len(data) <= 2:
                data.insert(0, (data[0][0], 0))
                #data.insert(len(data), data[-1][1])
            line = plot.PolyLine(data, legend=buddy_sn,
                                 colour=self.color_for_sn(buddy_sn), width=4)
            line_list.append(line)
            all_coords.extend(data)

        gc = plot.PlotGraphics(line_list, 'Line', 'X axiss', 'Y axis')
        min_x, max_x = self.get_min_max_for_axis('x', all_coords)
        min_y, max_y = self.get_min_max_for_axis('y', all_coords)

        self.label.SetLabel('')
        self.plotter.Enable()
        self.plotter.Draw(gc)#, xAxis=(min_x, max_x), yAxis=(min_y, max_y))

    def data_by_type(self, buddy_entry_list):
        data = []

        if self.view_type == QuantityPlotter.BYTES:
            data = [(e.start_time, e.size) for e in buddy_entry_list]
        elif self.view_type == QuantityPlotter.MSGS:
            data = [(e.start_time, e.msg_ct()) for e in buddy_entry_list]
        elif self.view_type == QuantityPlotter.CONVERSATIONS:
            for i, e in enumerate(buddy_entry_list):
                data.append((e.start_time, i))

        return data


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

