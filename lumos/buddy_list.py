import wx

class BuddyListCtrl(wx.ListCtrl):
  
  def __init__(self, parent, data_source):
    wx.ListCtrl.__init__(self, parent, style=wx.LC_REPORT|wx.LC_VIRTUAL)
    self.data_source = data_source

    self.Bind(wx.EVT_LIST_CACHE_HINT, self.DoCacheItems)
    self.SetItemCount(len(self.data_source))

    self.InsertColumn(0, 'Buddy SN')
    self.InsertColumn(1, 'Size')
    self.InsertColumn(2, 'Last Conversation Date')

    self.SetColumnWidth(0, wx.LIST_AUTOSIZE_USEHEADER)
    self.SetColumnWidth(1, wx.LIST_AUTOSIZE_USEHEADER)
    self.SetColumnWidth(2, wx.LIST_AUTOSIZE_USEHEADER)


  def DoCacheItems(self, evt):
    pass

  def OnGetItemText(self, item, col):
    data = self.data_source[item]
    return data[col]

  def OnGetItemAttr(self, item):  return None
  def OnGetItemImage(self, item): return -1

  def Update(self):
    return
