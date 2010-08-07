import wx
import wx.lib.plot as plot

import lumos.buddy_log_entry
import lumos.util

class ChatLogPlotter(wx.Panel):

    def __init__(self, parent, application):
        wx.Panel.__init__(self, parent)
        self.app = application

        self.plotter = plot.PlotCanvas(self)
        self.plotter.SetInitialSize(size=(400, 300))

        # don't ask me why the single element needs a sizer
        sizer = wx.BoxSizer(wx.HORIZONTAL)
        sizer.Add(self.plotter, 1, wx.EXPAND)
        self.SetSizer(sizer)

        self.draw_blank()
        self.cumulative = True
        self.current_buddy_sn_list = []

    def update(self, buddy_sn_list):
        if len(buddy_sn_list) == 0: return self.draw_blank()
        self.current_buddy_sn_list = buddy_sn_list

        # todo: decide how we feel about the view looking stuff up in the db
        # todo: figure out whether to pass this in or set as a const somewhere
        user_id = lumos.util.get_user_id(self.app.conn, lumos.util.get_current_sn())
        line_list = []
        all_coords = []
        for buddy_sn in buddy_sn_list:
            buddy_id = lumos.util.get_user_id(self.app.conn, buddy_sn)
            if self.cumulative:
                entries = lumos.buddy_log_entry.get_cumu_logs_for_user(
                    self.app.conn, user_id, buddy_id, buddy_sn)
            else:
                entries = lumos.buddy_log_entry.get_all_logs_for_user(
                    self.app.conn, user_id, buddy_id, buddy_sn)

            data = [(e.start_time, e.size) for e in entries]
            if self.app.debug:
                print '%d chats under %s' % (len(entries), buddy_sn)
                for e in entries:
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
        self.plotter.Draw(gc)#, xAxis=(min_x, max_x), yAxis=(min_y, max_y))

    def draw_blank(self):
        data = [(1,1), (4,2), (5, 2.5), (7, 4), (8, 7), (9, 20)]
        data2 = [(1, 3), (2, 1), (3, 2), (4, 2.5), (5, 1.5), (6, 2)]
        line = plot.PolyLine(data, colour='midnight blue',
                             width=1)
        line2 = plot.PolyLine(data2, colour='green', width=1)
        gc = plot.PlotGraphics([line, line2], 'examining awesomeness over time',
                               'Time (in eons)', 'awesomeness')
        self.plotter.SetEnableLegend(True)
        self.plotter.SetFontSizeLegend(10)
        self.plotter.SetXSpec(type='none')
        self.plotter.SetYSpec(type='none')
        min_x, max_x = self.get_min_max_for_axis('x', data)
        min_y, max_y = self.get_min_max_for_axis('y', data)
        self.plotter.Draw(gc)#, xAxis=(min_x, max_x), yAxis=(min_y, max_y))

    def get_min_max_for_axis(self, axis, data):
        idx = 0 if axis == 'x' else 1
        axis_data = [elt[idx] for elt in data]
        return [min(axis_data), max(axis_data)]

    def color_for_sn(self, buddy_sn):
        hsh = hash(buddy_sn)
        return wx.Color(hsh % 256, hsh / 256 % 256, hsh / 256 / 256 % 256)

    def set_cumulative(self, boolean):
        self.cumulative = boolean
        self.update(self.current_buddy_sn_list)
