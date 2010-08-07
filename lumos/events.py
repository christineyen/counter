import wx

lumos_LIST_ITEM_FOCUSED = wx.NewEventType()
lumos_QUANTITY_SETTINGS = wx.NewEventType()

EVT_LIST_ITEM_FOCUSED = wx.PyEventBinder(lumos_LIST_ITEM_FOCUSED, 0)
EVT_QUANTITY_SETTINGS = wx.PyEventBinder(lumos_QUANTITY_SETTINGS, 0)


class ListItemFocusedEvent(wx.PyEvent):
    def __init__(self, win_id, original_event, buddy_sns):
        wx.PyEvent.__init__(self, win_id, lumos_LIST_ITEM_FOCUSED)
        self.original_event = original_event
        self.buddy_sns = buddy_sns


class QuantitySettingsEvent(wx.PyEvent):
    def __init__(self, win_id, original_event, view_type):
        wx.PyEvent.__init__(self, win_id, lumos_QUANTITY_SETTINGS)
        self.original_event = original_event
        self.view_type = view_type

