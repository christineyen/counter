import wx
import wx.lib.mixins.listctrl as listmix

class BuddyListCtrl(wx.ListCtrl, listmix.ListCtrlAutoWidthMixin, listmix.ColumnSorterMixin):
  
  def __init__(self, parent, data_source, plotter):
    wx.ListCtrl.__init__(self, parent, -1, style=wx.LC_REPORT|wx.LC_VIRTUAL)

    self.plotter = plotter

    item_data_map = {}
    for idx, item in enumerate(data_source):
      item_data_map[idx] = item
    self.itemDataMap = item_data_map
    self.itemIndexMap = item_data_map.keys()
    self.SetItemCount(len(data_source))

    self.InsertColumn(0, 'Buddy SN')
    self.InsertColumn(1, 'Size')
    self.InsertColumn(2, 'Last Conversation Date')
    self.SetColumnWidth(2, 120)

    listmix.ListCtrlAutoWidthMixin.__init__(self)
    listmix.ColumnSorterMixin.__init__(self, 3)

    self.SortListItems(0)
    self.setResizeColumn(1)
    # events
    self.Bind(wx.EVT_LIST_COL_CLICK, self.OnColClick)
    self.Bind(wx.EVT_LIST_ITEM_SELECTED, self.OnItemSelected)
    
  def OnItemSelected(self, event):
    self.currentItem = event.m_itemIndex
    self.plotter.update(self.GetItemText(self.currentItem))

  def OnColClick(self, event):
    event.Skip()

  def GetListCtrl(self):
    return self

  def OnGetItemText(self, item, col):
    index = self.itemIndexMap[item]
    item = self.itemDataMap[index][col]
    if type(item) == int:
      return str(item)
    return item

  def OnGetItemAttr(self, item):  return None
  def OnGetItemImage(self, item): return -1

  def SortItems(self, sorter=cmp):
    items = list(self.itemDataMap.keys())

    items.sort(sorter)
    self.itemIndexMap = items

    self.Refresh()
