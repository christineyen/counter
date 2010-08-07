import unittest, sys, os

# update sys path to include bundled modules with priority
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from buddy_summary import BuddySummary

class TestBuddySummary(unittest.TestCase):

    def setUp(self):
        self.empty_summary = BuddySummary()
        self.summary = BuddySummary(size=5, ct=2, buddy_sn='sn', ts=5)
        pass

    def test_get_is_none(self):
        self.assertTrue(self.empty_summary.is_none())
        self.assertFalse(self.summary.is_none())

