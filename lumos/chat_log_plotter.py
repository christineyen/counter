import wx.lib.plot as plot
from buddy_log_entry import *

class ChatLogPlotter(plot.PlotCanvas):
  def __init__(self, parent, application):
    self.app = application
    # graphing nonsense - ordinarily would be instantiated with nothing
    data = [(1,2), (2,3), (3, 5), (4, 5), (5, 8), (6, 10)]
    data2 = [(1, 4), (2, 0), (3, 10), (4, 5), (5, 7), (6, 2)]
    plot.PlotCanvas.__init__(self, parent)
    line = plot.PolyLine(data, legend='blue', colour='midnight blue', width=1)
    line2 = plot.PolyLine(data2, legend='green', colour='green', width=1)
    gc = plot.PlotGraphics([line, line2], 'Line', 'X axiss', 'Y axis')
    self.SetEnableLegend(True)
    self.SetFontSizeLegend(10)
    self.Draw(gc, xAxis=(0, 8), yAxis=(0, 15))

  def update(self, buddy_sn):
    # todo: also decide how we feel about the view looking stuff up in the db
    user_id = 1 # todo: figure out whether to pass this in or just set it as some const somewhere
    buddy_id = get_user_id(self.app.conn, buddy_sn)

    entries = get_cum_log_entries_for_user(self.app.conn, user_id, buddy_id, buddy_sn)
    print '%d chats under %s' % (len(entries), buddy_sn)
    for e in entries:
      print e.to_string()

    '''line = plot.PolyLine(data, legend='blue', colour='red', width=1)
    gc = plot.PlotGraphics([line], 'Line', 'X axiss', 'Y axis')
    self.Draw(gc, xAxis=(0, 8), yAxis=(0, 15))'''
