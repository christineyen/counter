import wx

class DisplayOptions(wx.BoxSizer):
    def __init__(self, parent, plotter, pos=None):
        """ TODO: gross, i wish these options didn't have to touch the plotter
            directly"""
        wx.BoxSizer.__init__(self, wx.HORIZONTAL)
        self.plotter = plotter

        cumu_bytes = wx.RadioButton(parent, label='cumulative',
            style=wx.RB_GROUP)
        cumu_bytes.SetValue(True)
        self.Add(cumu_bytes, 1)

        # TODO(cyyen): consider replacing msgs with time length instead?
        cumu_msgs = wx.RadioButton(parent, label='cumu msgs')
        self.Add(cumu_msgs, 1)

        init_pct = wx.RadioButton(parent, label="init pct")
        self.Add(init_pct, 1)

        iter_bytes = wx.RadioButton(parent, label='iterative')
        self.Add(iter_bytes, 1)

        iter_msgs = wx.RadioButton(parent, label="iter msgs")
        self.Add(iter_msgs, 1)

        parent.Bind(wx.EVT_RADIOBUTTON, self.change_settings)

    def change_settings(self, event):
        self.plotter.set_cumulative(event.EventObject.GetLabel() ==
                                    "cumulative")
