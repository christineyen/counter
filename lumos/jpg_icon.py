import wx

class JpgIcon(wx.TaskBarIcon):

  def __init__(self, frame):
    wx.TaskBarIcon.__init__(self)
    self.frame = frame

    # Set the image
    icon_img = wx.ImageFromMime('icon.jpg', 'image/jpeg')
    self.SetIcon(self.MakeIcon(icon_img), "lumos")
    self.imgidx = 1

  def MakeIcon(self, img):
    """
    The various platforms have different requirements for the
    icon size...
    """
    if "wxMSW" in wx.PlatformInfo:
      print 'msw'
      img = img.Scale(16, 16)
    elif "wxGTK" in wx.PlatformInfo:
      print 'gtk'
      img = img.Scale(22, 22)
    # wxMac can be any size upto 128x128, so leave the source img alone....
    icon = wx.IconFromBitmap(img.ConvertToBitmap() )
    return icon
