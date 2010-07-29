import wx
import wx.lib.mixins.listctrl as listmix

class BuddyListCtrl(wx.ListCtrl, listmix.ListCtrlAutoWidthMixin,
                    listmix.ColumnSorterMixin):

    def __init__(self, parent, plotter, pos=None, size=None):
        wx.ListCtrl.__init__(self, parent, -1, pos=None, size=size,
            style=wx.LC_REPORT|wx.LC_VIRTUAL)

        self.plotter = plotter

        self.update_data([])

        self.InsertColumn(0, 'Buddy SN')
        self.InsertColumn(1, 'Size')
        self.InsertColumn(2, 'Last Conversation Date')
        self.SetColumnWidth(2, 120)

        listmix.ListCtrlAutoWidthMixin.__init__(self)
        listmix.ColumnSorterMixin.__init__(self, 3)

        self.SortListItems(0)
        self.setResizeColumn(1)
        # events
        self.Bind(wx.EVT_LIST_ITEM_SELECTED, self.on_item_focused)
        self.Bind(wx.EVT_LIST_ITEM_DESELECTED, self.on_item_focused)

    def update_data(self, data):
        item_data_map = {}
        for idx, item in enumerate(data):
            item_data_map[idx] = item
        self.itemDataMap = item_data_map
        self.itemIndexMap = item_data_map.keys()
        self.SetItemCount(len(data))


    def on_item_focused(self, event):
        self.currentItem = event.m_itemIndex
        indices = self.get_selected_indices()
        buddy_sns = [self.GetItemText(e) for e in indices]
        self.plotter.update(buddy_sns)

    def get_selected_indices(self):
        idx = -1
        arr = []
        while True:
            idx = self.GetNextSelected(idx)
            if idx == -1: break
            arr.append(idx)
        return arr

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
