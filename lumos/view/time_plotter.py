from datetime import datetime
import matplotlib.ticker as ticker

import wx

import lumos.events
import lumos.view.plotter

class TimePlotter(lumos.view.plotter.Plotter):
    # ViewType
    TIME_OF_DAY = 0
    LENGTH = 1

    def __init__(self, parent, application):
        lumos.view.plotter.Plotter.__init__(self, parent, application,
            "Properties of logs by time of day and duration")
        self.view_type = self.view_types().items()[0][1]

        # Consider factoring into skew_plotter
        options = lumos.view.plotter.Options(self,
            label='view by:',
            view_types=self.view_types().keys(),
            event_class=lumos.events.TimeSettingsEvent)

        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 14, wx.EXPAND)
        self.sizer.Add(options, 1, wx.EXPAND)
        self.SetSizer(self.sizer)

        self.Bind(lumos.events.EVT_TIME_SETTINGS, self.on_settings_change)

    def draw(self, buddy_sns=[], ble_entries=[]):
        ''' Draws a plot based on some time-related attribute...'''
        if self.view_type == TimePlotter.TIME_OF_DAY:
            self.draw_time_of_day(buddy_sns, ble_entries)
        elif self.view_type == TimePlotter.LENGTH:
            self.draw_length(buddy_sns, ble_entries)

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

    def draw_length(self, buddy_sns=[], ble_entries=[]):
        ''' Draws bars, representing the duration of the conversation, against
            time.

            TODO: make this less UGLY, please
        '''
        axes = self.figure.gca()
        collections = []
        for i, ble_list in enumerate(ble_entries):
            left = []; heights = []; bottoms = []
            for entry in ble_list:
                start = datetime.fromtimestamp(entry.start_time)
                end = datetime.fromtimestamp(entry.end_time)
                top = int(end.strftime('%H%M'))
                bottom = int(start.strftime('%H%M'))
                if top < bottom: # if the conversation went past midnight
                    left.append(start)
                    heights.append(2400 - bottom)
                    bottoms.append(bottom)

                    left.append(start)
                    heights.append(top)
                    bottoms.append(0)
                else:
                    left.append(start)
                    heights.append(top - bottom)
                    bottoms.append(bottom)
            bar = axes.bar(left, heights, bottom=bottoms,
                color=self.color_for_sn(ble_list[0].buddy_sn),
                align='center')
            collections.append(bar)
        axes.get_xaxis().set_major_formatter(lumos.view.plotter.FORMATTER)
        axes.get_yaxis().set_major_formatter(LengthYFormatter())
        axes.set_ybound(0, 2400)
        self.figure.legend(collections, buddy_sns, 'upper left',
            prop={'size': 'small'})
        self.figure.canvas.draw()

    def view_types(self):
        ''' Used to map the label text to a ViewType. '''
        return {
            'time of day': TimePlotter.TIME_OF_DAY,
            'length': TimePlotter.LENGTH
        }



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

class LengthYFormatter(ticker.Formatter):
    def __call__(self, y, pos=0):
        y_str = str(y).split('.')[0]
        hour = y_str[0:2]
        minute = y_str[2:len(y_str)]
        return hour + ':' + minute
