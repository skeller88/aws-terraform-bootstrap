import unittest

from nose.tools import eq_


class Dummy(unittest.TestCase):
    """
    Either run this test via pycharm or via the command line:
    nosetests test/hello_world.py --nocapture
    """
    @classmethod
    def setUpClass(cls):
        cls.class_variable = 'class'

    def setUp(self):
        self.instance_variable = 'instance'

    def test_class_variable(self):
        eq_(self.class_variable, 'class')

    def test_instance_variable(self):
        eq_(self.instance_variable, 'instance')