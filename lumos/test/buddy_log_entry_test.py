import unittest

class TestBuddyLogEntry(unittest.TestCase):

    def setUp(self):
        pass

    def test_get_logs(self):
        self.assertTrue(True)

    def test_get_something_else(self):
        self.assertTrue(True)

def suite():
    suite = unittest.TestSuite()
    suite.addTest(unittest.makeSuite(TestBuddyLogEntry))
    return suite

if __name__ == '__main__':
    unittest.main()
