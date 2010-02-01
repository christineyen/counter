import wx.lib.plot as plot
from buddy_log_entry import *

class ChatLogPlotter(plot.PlotCanvas):
  def __init__(self, parent, application):
    self.app = application
    # graphing nonsense - ordinarily would be instantiated with nothing
    plot.PlotCanvas.__init__(self, parent)
    self.draw_blank()

  def update(self, buddy_sn_list):
    if len(buddy_sn_list) == 0: return self.draw_blank()

    # todo: also decide how we feel about the view looking stuff up in the db
    user_id = 1 # todo: figure out whether to pass this in or just set it as some const somewhere

    line_list = []
    all_coords = []
    for buddy_sn in buddy_sn_list:
      buddy_id = get_user_id(self.app.conn, buddy_sn)
      entries = get_cum_log_entries_for_user(self.app.conn, user_id, buddy_id, buddy_sn)
      data = [(e.start_time, e.size) for e in entries]
      '''print '%d chats under %s' % (len(entries), buddy_sn)
      for e in entries:
        print e.to_string()''' # todo: find a way to have a 'debug' option!
      if len(data) > 0 and len(data) <= 2:
        data.insert(0, (data[0][0], 0))
        #data.insert(len(data), data[-1][1])
      print str(data)
      line = plot.PolyLine(data, legend=buddy_sn, colour='red', width=1)
      line_list.append(line)
      all_coords.extend(data)

    gc = plot.PlotGraphics(line_list, 'Line', 'X axiss', 'Y axis')
    min_x, max_x = self.get_min_max_for_axis('x', all_coords)
    min_y, max_y = self.get_min_max_for_axis('y', all_coords)
    self.Draw(gc, xAxis=(min_x, max_x), yAxis=(min_y, max_y))

  def draw_blank(self):
    data = [(1,1), (4,2), (5, 2.5), (7, 4), (8, 7), (9, 20)]
    data2 = [(1, 3), (2, 1), (3, 2), (4, 2.5), (5, 1.5), (6, 2)]
    line = plot.PolyLine(data, legend='christine', colour='midnight blue', width=1)
    line2 = plot.PolyLine(data2, legend='the world', colour='green', width=1)
    gc = plot.PlotGraphics([line, line2], 'examining awesomeness over time', 'Time (in eons)', 'awesomeness')
    self.SetEnableLegend(True)
    self.SetFontSizeLegend(10)
    min_x, max_x = self.get_min_max_for_axis('x', data)
    min_y, max_y = self.get_min_max_for_axis('y', data)
    self.Draw(gc, xAxis=(min_x, max_x), yAxis=(min_y, max_y))

  def get_min_max_for_axis(self, axis, data):
    idx = 0 if axis == 'x' else 1
    axis_data = [elt[idx] for elt in data]
    return [min(axis_data), max(axis_data)]


