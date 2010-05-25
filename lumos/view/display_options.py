import wx

class DisplayOptions(wx.BoxSizer):
  def __init__(self, parent, plotter):
    """ TODO: gross, i wish these options didn't have to touch the plotter directly"""
    wx.BoxSizer.__init__(self, wx.HORIZONTAL)
    self.plotter = plotter

    cumu = wx.RadioButton(parent, -1, 'cumulative', style = wx.RB_GROUP)
    cumu.SetValue(True)
    iter = wx.RadioButton(parent, 1, 'iterative')
    self.Add(cumu, 1)
    self.Add(iter, 1)

    parent.Bind(wx.EVT_RADIOBUTTON, self.change_settings)

  def change_settings(self, event):
    self.plotter.set_cumulative(event.EventObject.GetLabel() == "cumulative")
