import matplotlib
from matplotlib import dates
matplotlib.use('WxAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg

# set matplotlib rc settings
matplotlib.rc('font', size=10.0)

import wx

import lumos.buddy_log_entry

DRAW_BLANK_TEXT= '''You have not selected any conversations to graph.\n
Please click on one or more buddy screen names on the left\n
to see results graphed in this space. '''

FORMATTER = dates.DateFormatter('%m/%y')

class Plotter(wx.Panel):

    def __init__(self, parent, title):
        wx.Panel.__init__(self, parent)

        self.figure = matplotlib.figure.Figure(dpi=None, figsize=(2,2))
        self.figure.set_facecolor('white')
        self.canvas = FigureCanvasWxAgg(self, -1, self.figure)

        self.draw_blank()
        self.current_buddy_sn_list = []

    def update(self, buddy_sns):
        ''' The general 'update' logic for a plotter. Subclasses override
            draw() in order to provide unique behavior.

            @param buddy_sns A list of strings representing buddy screen names.
            '''
        if len(buddy_sns) == 0: return self.draw_blank()
        self.current_buddy_sn_list = buddy_sns

        # TODO: decide how we feel about the view looking stuff up in the db
        ble_entries = lumos.buddy_log_entry.get_cumu_logs_for_set(buddy_sns)

        self.figure.clear()
        self.figure.gca().clear()
        self.draw(buddy_sns=buddy_sns, ble_entries=ble_entries)

    def draw(self, buddy_sns=[], ble_entries=[]):
        ''' Override to define plotter-specific drawing behavior.

            @param buddy_sns A list of strings representing buddy screen names.
            @param ble_entries A list of lists per buddy of BuddyLogEntrys.
        '''
        pass # abstract

    def draw_blank(self, text=DRAW_BLANK_TEXT):
        all_entries = lumos.buddy_log_entry.get_cumu_logs_for_all()
        self.figure.clear()
        self.figure.gca().clear()
        self.draw(buddy_sns=['representative sample'], ble_entries=all_entries)

    def color_for_sn(self, buddy_sn):
        hsh = hash(buddy_sn)
        def norm(num):
            return num / 256.0
        return norm(hsh % 256), norm(hsh / 256 % 256), norm(hsh / 256 / 256 % 256)

    def on_settings_change(self, event):
        if event.view_type not in self.view_types().keys():
            raise "unknown or null view type passed in!"

        self.view_type = self.view_types()[event.view_type]
        print self.__class__.__name__ + " is now: " + str(self.view_type)
        self.update(self.current_buddy_sn_list)

    def view_types(self):
        pass # abstract

    def print_debug_info(self, ble_list, x, y):
        print '%d chats w/ %s' % (len(ble_list), ble_list[0].buddy_sn)
        print 'x: ' + str(x)
        print 'y: ' + str(y)

class Options(wx.Panel):
    def __init__(self, parent, label='', view_types=[], event_class=None):
        ''' Return a generic Options panel, customizable based on the arguments.

            @param view_types An (ordered!) list of labels showing all settings.
            @param event_class The wx.EventType this class should post.
        '''
        wx.Panel.__init__(self, parent)
        self.event_class = event_class
        sizer = wx.BoxSizer(wx.HORIZONTAL)

        label_elt = wx.StaticText(self, label=label)
        sizer.Add(label_elt, 1)

        for i, view_type in enumerate(view_types):
            if i == 0:
                btn = wx.RadioButton(self, label=view_type, style=wx.RB_GROUP)
                btn.SetValue(True)
            else:
                btn = wx.RadioButton(self, label=view_type)
            sizer.Add(btn, 1)

        self.SetSizer(sizer)

        self.Bind(wx.EVT_RADIOBUTTON, self.on_options_settings_change)

    def on_options_settings_change(self, event):
        view_type = event.EventObject.GetLabel()

        print "Posting event of class: " + str(self.event_class)
        wx.PostEvent(self.GetParent(),
            self.event_class(self.GetId(), event, view_type))

