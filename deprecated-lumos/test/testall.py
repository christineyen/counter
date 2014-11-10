import unittest

import buddy_summary_test
import buddy_log_entry_test


suite = unittest.TestSuite()
suite.addTest(unittest.makeSuite(buddy_summary_test.TestBuddySummary))
suite.addTest(unittest.makeSuite(buddy_log_entry_test.TestBuddyLogEntry))

unittest.TextTestRunner(verbosity=2).run(suite)
