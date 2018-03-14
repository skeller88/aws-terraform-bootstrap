import unittest

import os
from nose.tools import eq_

from src import hello_world
from src.hello_world import dummy_secret

from src.properties import Properties


class HelloWorldTest(unittest.TestCase):
    """
    Either run this test via pycharm,

    via the command line:
    nosetests test/test_hello_world.py --nocapture

    or via a bash script which runs this test multiple times with different combinations of environment variables:

    ./<aws-terraform-bootstrap-dir>/run_tests.sh
    """
    @classmethod
    def setUpClass(cls):
        cls.class_variable = 'class'

    def setUp(self):
        self.instance_variable = 'instance'

    def test_hello_world(self):
        """
        Assert environment variables are as expected, and that the app doesn't throw any exceptions.
        """
        print(Properties.use_aws, Properties.storage_type)
        eq_(Properties.use_aws, os.environ.get('USE_AWS') == 'True')
        eq_(Properties.storage_type, os.environ.get('STORAGE_TYPE'))
        response = hello_world.hello_world(None, None)

        if not Properties.use_aws:
            eq_(response.get('secret'), dummy_secret)
