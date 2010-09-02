from datetime import datetime
import matplotlib.ticker as ticker

import wx

import lumos.events
import lumos.view.plotter

class TimePlotter(lumos.view.plotter.Plotter):
    # ViewType
    TIME_OF_DAY = 0
    LENGTH = 1

    # Used to map the label text to a ViewType.
    VIEW_TYPES = {
        'time of day': TIME_OF_DAY,
        'length': LENGTH
    }

    def __init__(self, parent, application):
        lumos.view.plotter.Plotter.__init__(self, parent, application,
            "Properties of logs by time of day and duration")
        self.view_type = TimePlotter.TIME_OF_DAY

        # Consider factoring into skew_plotter
        options = TimeOptions(self, pos=(0, 460))

        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 14, wx.EXPAND)
        self.sizer.Add(options, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

        self.Bind(lumos.events.EVT_QUANTITY_SETTINGS, self.on_settings_change)

    def draw(self, buddy_sns=[], ble_entries=[]):
        ''' Draws a plot based on some time-related attribute...'''
        if self.view_type == TimePlotter.TIME_OF_DAY:
            self.draw_time_of_day(buddy_sns, ble_entries)
        elif self.view_type == TimePlotter.LENGTH:
            self.draw_length(buddy_sns, ble_entries)
        else:
            self.draw_blank("Invalid type of Time plot selected.")

    def draw_time_of_day(self, buddy_sns=[], ble_entries=[]):
        ''' Draws bubbles based on the # conversations per hour of day
            and day of week.

            We only handle the first ble_list.
        '''
        axes = self.figure.gca()
        collections = []
        for ble_list in ble_entries:
            xy_values = {}
            for entry in ble_list:
                ts = datetime.fromtimestamp(entry.start_time)
                xy = (ts.hour, ts.weekday())
                if xy not in xy_values:
                    xy_values[xy] = 10
                # each incremental conv is 2x larger in radius
                xy_values[xy] *= 2
            x = []; y = []; sizes = []
            for x_val, y_val in xy_values.keys():
                x.append(x_val)
                y.append(y_val)
                sizes.append(xy_values[(x_val, y_val)])
            coll = axes.scatter(x, y, sizes,
                c=self.color_for_sn(ble_list[0].buddy_sn),
                linewidths=1,
                alpha=0.75)
            collections.append(coll)
        axes.set_xbound(-0.5, 24)
        axes.get_xaxis().set_major_formatter(TimeOfDayXFormatter())
        axes.set_ybound(-0.5, 6.5)
        axes.get_yaxis().set_major_formatter(TimeOfDayYFormatter())
        self.figure.legend(collections, buddy_sns, 'upper left',
            prop={'size': 'small'})
        self.figure.canvas.draw()

    def time_of_day_x_formatter(self):
        l

    def time_of_day_y_formatter(self):
        pass

    def draw_length(self, buddy_sns=[], ble_entries=[]):
        ''' Draws bars, representing the duration of the conversation, against
            time.
        '''
        pass

    def on_settings_change(self, event):
        self.view_type = event.view_type
        print "TimePlotter.view_type is now: " + str(self.view_type)
        self.update(self.current_buddy_sn_list)


# TODO: clean up by creating a generic Options class in plotter.py,
# pass in dictionary or kwargs to define buttons / labels?
class TimeOptions(wx.Panel):
    def __init__(self, parent, pos=None):
        """ TODO: gross, i wish these options didn't have to touch the plotter
            directly"""
        wx.Panel.__init__(self, parent)
        sizer = wx.BoxSizer(wx.HORIZONTAL)

        label = wx.StaticText(self, label='view by: ')
        sizer.Add(label, 1)

        type = 'time of day'
        time_of_day = wx.RadioButton(self, label=type, style=wx.RB_GROUP)
        time_of_day.SetValue(True)
        sizer.Add(time_of_day, 1)

        type = 'length'
        length = wx.RadioButton(self, label=type)
        sizer.Add(length, 1)

        self.SetSizer(sizer)

        self.Bind(wx.EVT_RADIOBUTTON, self.on_options_settings_change)

    def on_options_settings_change(self, event):
        view_type = event.EventObject.GetLabel()

        if view_type not in TimePlotter.VIEW_TYPES.keys():
            raise "unknown or null view type passed in!"

        view_type = TimePlotter.VIEW_TYPES.get(view_type)
        wx.PostEvent(self.GetParent(),
            lumos.events.TimeSettingsEvent(self.GetId(), event, view_type))

class TimeOfDayXFormatter(ticker.Formatter):
    def __call__(self, x, pos=0):
        return str(x).split('.')[0] + ':00'

class TimeOfDayYFormatter(ticker.Formatter):
    def __call__(self, y, pos=0):
        int_to_day_of_week = {
            0: 'Mon',
            1: 'Tues',
            2: 'Wed',
            3: 'Thurs',
            4: 'Fri',
            5: 'Sat',
            6: 'Sun' }
        return int_to_day_of_week.get(int(y), '')

