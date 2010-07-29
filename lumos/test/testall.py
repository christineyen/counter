import unittest

import buddy_summary_test

buddy_summary_suite = buddy_summary_test.suite()

suite = unittest.TestSuite()
suite.addTest(buddy_summary_suite)
unittest.TextTestRunner(verbosity=2).run(suite)
