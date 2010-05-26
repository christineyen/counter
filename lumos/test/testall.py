import unittest

import buddy_log_entry_test

buddy_log_entry_suite = buddy_log_entry_test.suite()

suite = unittest.TestSuite()
suite.addTest(buddy_log_entry_suite)
unittest.TextTestRunner(verbosity=2).run(suite)
