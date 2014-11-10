from datetime import datetime

import wx
import wx.lib.mixins.listctrl as listmix

import lumos.events

class BuddyListCtrl(wx.ListCtrl, listmix.ListCtrlAutoWidthMixin,
                    listmix.ColumnSorterMixin):

    def __init__(self, parent, pos=None, size=None):
        wx.ListCtrl.__init__(self, parent, -1, pos=None, size=size,
            style=wx.LC_REPORT|wx.LC_VIRTUAL)

        # Un-comment out when we figure out why the horizontal scrollbar
        # re-appears.
        # listmix.ListCtrlAutoWidthMixin.__init__(self)
        listmix.ColumnSorterMixin.__init__(self, 3)

        self.update_data([])

        self.InsertColumn(0, 'Buddy SN', width=125)
        self.InsertColumn(1, '#', width=30)
        self.InsertColumn(2, 'Last Chat Date', width=120)

        self.SortListItems(0)
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

    def get_selected_buddy_sns(self):
        indices = self.get_selected_indices()
        return [self.GetItemText(e) for e in indices]

    def on_item_focused(self, event):
        self.currentItem = event.m_itemIndex
        buddy_sns = self.get_selected_buddy_sns()
        wx.PostEvent(self.GetParent(),
            lumos.events.ListItemFocusedEvent(self.GetId(), event, buddy_sns))

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
        if type(item) == datetime:
            return item.strftime('%m/%d/%y')
        return item

    def OnGetItemAttr(self, item):  return None
    def OnGetItemImage(self, item): return -1

    def SortItems(self, sorter=cmp):
        items = list(self.itemDataMap.keys())

        items.sort(sorter)
        self.itemIndexMap = items

        self.Refresh()
