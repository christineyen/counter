import sys

import lumos.main

if __name__ == '__main__':
    debug_val = ('-d' in sys.argv)
    l = lumos.main.Lumos(redirect=False, debug=debug_val)
    l.MainLoop()
